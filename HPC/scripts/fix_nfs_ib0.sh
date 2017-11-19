#!/bin/bash


# Once ib0 network is configured we can switch NFS to run over IPoIB
# launch this script on the nodes as 
#
# pdsh /share/installs/fix_nfs_ib0 IB
#
# or to go back to Ethernet:
#
# pdsh /share/installs/fix_nfs_ib0 ETH

data=`date +"%d-%m-%Y"`

cp /etc/fstab /etc/fstab.last
cp /etc/fstab /etc/fstab.bak-$data


case "$1" in 

IB)
# NFS over IB (IPoIB) 172.16.1.0/24 is IB network
sed 's/^172.16.0/172.16.1/' /etc/fstab.bak-$data > /etc/fstab
;;
ETH)
# NFS over Ethernet
sed 's/^172.16.1/172.16.0/' /etc/fstab.bak-$data > /etc/fstab
;;
esac

umount /home
umount /share

mount /home
mount /share


