#!/bin/bash

# this script configures IB network on the master node then on compute nodes


cp ../configs/ifcfg-ib0 /share/installs/ifcfg-ib0
cp /share/installs/ifcfg-ib0 /etc/sysconfig/network-scripts/

#master ib0 IP
my_ib_ip="172.16.1.1"

echo "IPADDR=$my_ib_ip" >> /etc/sysconfig/network-scripts/ifcfg-ib0

ifdown ib0
ifup ib0

HOST=${HOSTNAME%%.*}

ssh 172.16.0.1 "echo $my_ib_ip	$HOST-ib0 >> /etc/hosts"



#### does the same on the nodes:
cp ./ifup_ib0_nodes.sh /share/installs/
chmod +x /share/installs/ifup_ib0_nodes.sh
pdsh /share/installs/ifup_ib0_nodes.sh



### change NFS to run over IB or back

cp ./fix_nfs_ib0.sh /share/installs/

# switch NFS to IB

pdsh /share/installs/fix_nfs_ib0.sh IB

# or go back to Ethernet

# pdsh /share/installs/fix_nfs_ib0.sh ETH