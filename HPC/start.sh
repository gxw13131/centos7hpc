# Run as sh ./start.sh isoname.iso

# Note: your external network interface must be configuured, up and running
# It will be put in "external zone" of firewalld by this script

### some prerequisites #### for e.g. "wget" and firewall
chmod -R +x ./scripts/*

yum -y install net-tools firewalld #NetworkManager

#service NetworkManager restart

service start firewalld

####  Centos 7 PXE install server installation ######

if [ "$1" = "-h" ]; then
  echo "Usage: `basename $0` /path/to/CentOS_DVD.iso"
  echo "If you need to download CentOS DVD, use just `basename $0 ` -d"
  exit 0
elif [ "$1" = "-d" ]; then
echo "Downloading 4Gb ISO file"
wget http://anorien.csc.warwick.ac.uk/mirrors/centos/7/isos/x86_64/CentOS-7-x86_64-DVD-1708.iso
isoname="CentOS-7-x86_64-DVD-1708.iso"

elif [ "$1" = "" ]; then
    echo "You have to supply the location if the CentOS 7 ISO file see `basename $0 -h`"
  exit 0
fi


test=0 #local test if we know our devices

if [ "$test" = "1" ]; then

    eth_int="enp0s8"
    eth_ext="enp0s3"
else
    #define internal and external network interfaces
    echo "Here is the list of your network interfaces:"

    ip link show

    echo "Enter your internal network interface here: (e.g. enp4s0), it will be configured with IP: 172.16.0.1 (zone internal):"
    read eth_int

    echo "Enter your external network interface name: (e.g. enp4s1):"
    read eth_ext
fi
###################### HOSTNAME of headnode #################
echo NETWORKING=yes > /etc/sysconfig/network
echo HOSTNAME=master > /etc/sysconfig/network


############################# START configuring server ############################

# disable SELINUX temporarely
setenforce 0
# Disable SELINUX permanently in /etc/sysconfig/selinux:
sed 's/^SELINUX=.*/SELINUX=disabled/' /etc/selinux/config > /etc/selinux/config.tmp; mv -f /etc/selinux/config.tmp /etc/selinux/config

# ssh client
echo "   StrictHostKeyChecking no" >> /etc/ssh/ssh_config

# disable yum auto updates
systemctl disable packagekitd 

#clean hosts file (nodes will fill it themselves later)
echo "127.0.0.1               localhost.localdomain localhost" > /etc/hosts

# get the name of ISO file
isoname=$1

#### config internal network
cp ./configs/ifcfg-server /etc/sysconfig/network-scripts/ifcfg-$eth_int
echo DEVICE=\"$eth_int\" >> /etc/sysconfig/network-scripts/ifcfg-$eth_int
echo ZONE=\"internal\" >>  /etc/sysconfig/network-scripts/ifcfg-$eth_int

ifconfig $eth_int down
ifconfig $eth_int 172.16.0.1 netmask 255.255.255.0 broadcast 172.16.0.255
ifconfig $eth_int up
ifup $eth_int
ifup $eth_ext

###################### Attempt to configure NAT #########################

./scripts/firewall.sh $eth_int $eth_ext

#########################################################################


# CentOS ISO image mounted in web server tree
installpath="/var/www/html/centos"
mkdir -p $installpath
umount $installpath # if previous installs left it there

#systemctl disable firewalld
#systemctl stop firewalld


# install required rpm's
yum install epel-release -y
yum -y install httpd xinetd dhcp tftp tftp-server syslinux wget vsftpd opensm pdsh infiniband-diags nfs-utils 


################################ NFS-server config #############################
mkdir -p /share

echo "/home            *(rw,sync,no_root_squash,no_all_squash)" > /etc/exports
echo "/share           *(rw,sync,no_root_squash,no_all_squash)" >> /etc/exports


#chmod -R 755 /home
systemctl enable rpcbind
systemctl enable nfs-server
#systemctl enable nfs-lock
#systemctl enable nfs-idmap
systemctl restart rpcbind
systemctl restart nfs-server
#systemctl start nfs-lock
#systemctl start nfs-idmap

########################## TFTPD & DHCPD ################################################

mkdir -p /tftpboot
mkdir -p /tftpboot/pxelinux.cfg
mkdir -p /tftpboot/netboot/
chmod -R 777 /tftpboot

cp -f ./configs/dhcpd.conf /etc/dhcp/
cp -f ./configs/tftp /etc/xinetd.d/
cp -f ./configs/ks.cfg /var/www/html/
cp -f ./configs/default /tftpboot/pxelinux.cfg/
cp -f ./configs/localboot /tftpboot/pxelinux.cfg/
cp -f ./scripts/post.sh /var/www/html/
cp -f ./configs/ifcfg-node /var/www/html/
cp -f ./configs/sshd_config /var/www/html/

cp -v /usr/share/syslinux/pxelinux.0 /tftpboot/
cp -v /usr/share/syslinux/menu.c32 /tftpboot/
cp -v /usr/share/syslinux/memdisk /tftpboot/
cp -v /usr/share/syslinux/mboot.c32 /tftpboot/
cp -v /usr/share/syslinux/chain.c32 /tftpboot/



# ISO name must be present as a parameter of this script
echo "Mounting "$isoname "...."

mount -o loop -t iso9660 ${isoname} ${installpath}

cp $installpath/images/pxeboot/vmlinuz /tftpboot/netboot/
cp $installpath/images/pxeboot/initrd.img /tftpboot/netboot/

chkconfig dhcpd on
chkconfig xinetd on
chkconfig vsftpd on
chkconfig sshd on

service vsftpd  restart
service dhcpd restart
service xinetd   restart
service httpd restart


#### for post-intall client need to copy over its MAC to /tftp/pxelinux.cfg to avoid going ito install after 1st reboot
#### we give it access to server with ssh key: it will grab via http, see post-install script post.sh executed from ks.cfg

ssh-keygen -f /var/www/html/id_rsa.tmp -t rsa -N """"
chmod 755 /var/www/html/id*

# delete previous temp keys

mkdir -p ~/.ssh
rm -f ~/.ssh/authorized_keys

cat /var/www/html/id_rsa.tmp.pub >> ~/.ssh/authorized_keys
cp -f /var/www/html/id_rsa.tmp ~/.ssh/id_rsa
cp -f /var/www/html/id_rsa.tmp.pub ~/.ssh/id_rsa.pub
rm ~/.ssh/known_hosts
chmod -R 600 ~/.ssh/


echo "Now go and switch on the compute nodes!"
echo "After nodes are deployed, remove the rsa keys from /var/www/html/ folder for security (keep key if you plan re-deployment)!"

# pdsh stuff
cp -f ./scripts/pdsh.sh /etc/profile.d/
mkdir -p /etc/pdsh
echo "" > /etc/pdsh/machines
source /etc/profile.d/pdsh.sh
echo source /etc/profile.d/pdsh.sh >> /etc/bashrc
echo "Also check optional ./scripts/postinstall_from_server.sh script!"


