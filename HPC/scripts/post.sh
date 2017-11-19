##### POST INSTALL FILE FOR THE NODES #######
# do not launch it manually!
# this script is executed by the end of kickstart install from the nodes automatically

sed 's/^SELINUX=.*/SELINUX=disabled/' /etc/selinux/config > /etc/selinux/config.tmp; mv -f /etc/selinux/config.tmp /etc/selinux/config

extDNS="208.67.220.220" # external openDNS server IP (put your own if you like)
masterIP="172.16.0.254"

# My eth0 MAC-ADDRESS

IFS=' ' read -r -a mymacs <<< $(cat /sys/class/net/e*/address)

#mac1=${macarray[0]}
#mac2=${macarray[1]}



# get temp rsa keys
mkdir -p /root/.ssh

wget http://${masterIP}/id_rsa.tmp
wget http://${masterIP}/id_rsa.tmp.pub

mv id_rsa.tmp /root/.ssh/id_rsa
mv id_rsa.tmp.pub /root/.ssh/id_rsa.pub

cat /root/.ssh/id_rsa.pub >> /root/.ssh/authorized_keys
chmod -R 600 /root/.ssh


################# Updating my MAC record in the server's PXE boot file ####################

in="/tftpboot/pxelinux.cfg/localboot"

for mac in ${mymacs[@]};
do
	out="/tftpboot/pxelinux.cfg/01-${mac//:/-}"
	echo "$mac to $out"
	ssh -v -i /root/.ssh/id_rsa -o "StrictHostKeyChecking no " ${masterIP} "cp -f $in  $out;exit"
done 

################### Configure NETWORK #####################
wget http://${masterIP}/ifcfg-node

# get first net device
device=($(ls /sys/class/net/ | grep enp))

# My IP address
IP=$(ip route get 8.8.8.8| grep src | sed 's/.*src \(.*\)$/\1/g')

cp -f ifcfg-node /etc/sysconfig/network-scripts/ifcfg-$device
echo "DEVICE=$device" >> /etc/sysconfig/network-scripts/ifcfg-$device
echo "ZONE=internal" >> /etc/sysconfig/network-scripts/ifcfg-$device

echo "StrictHostKeyChecking	no" >> /etc/ssh/ssh_config




################# UPDATING my DHCP record in server's /etc/dhcp/dhcpd.conf #####################

# constructing dhcpd.conf for server

oldIP=${IP##*.}
N=${oldIP}
SIP="172.16.0.$N" # this will be my new static IP issued by dhcpd on reboot
HOSTNAME="node$N"
echo $HOSTNAME > /etc/hostname

ssh -i /root/.ssh/id_rsa -o "StrictHostKeyChecking no " ${masterIP} "echo $IP	$HOSTNAME.local	$HOSTNAME >>/etc/hosts"
ssh -i /root/.ssh/id_rsa -o "StrictHostKeyChecking no " ${masterIP} "echo $HOSTNAME >>/etc/pdsh/machines"

mydhcp="host $HOSTNAME { hardware ethernet $mac; option host-name \"\"$HOSTNAME\"\"; fixed-address $SIP; }"
ssh -i /root/.ssh/id_rsa -o "StrictHostKeyChecking no " ${masterIP} "echo \"$mydhcp\" >>/etc/dhcp/dhcpd.conf"
ssh -i /root/.ssh/id_rsa -o "StrictHostKeyChecking no " ${masterIP} "ln -s $out /tftpboot/pxelinux.cfg/node$N"

################# NFS-shares #############################

rm -fr /home

mkdir /home
mkdir /share

echo "${masterIP}:/home /home  nfs     rw      0       0" >> /etc/fstab
echo "${masterIP}:/share /share  nfs     rw      0       0" >> /etc/fstab

echo "mount /home" >> /etc/rc.local
echo "mount /share" >> /etc/rc.local

chmod +x /etc/rc.d/rc.local
systemctl start rc-local

#sync clock
date --set="$(curl -s --head http://${masterIP}/ | grep ^Date: | sed 's/Date: //g')"
hwclock --systohc

wget http://${masterIP}/sshd_config 
cp -f sshd_config /etc/ssh/sshd_config

# setting headnode's hostname
masterlong=$(ssh -i /root/.ssh/id_rsa -o "StrictHostKeyChecking no " ${masterIP} hostname)
mastershort=${masterlong%%.*}

echo "${masterIP}	$mastershort	$masterlong" >> /etc/hosts


#### DNS resolution on nodes ####

echo "search $masterlong" > /etc/resolv.conf
echo "nameserver ${extDNS}" >> /etc/resolv.conf # external DNS server

