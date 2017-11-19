#!/bin/bash
#
# this script configures IB network on the nodes,
# this script is called from ifup_ib0_master.sh


# Otherwise, execute on server prior to this script:
# cp ./ifcfg-ibo /share/installs/ifcfg-ib0
# i.e. to copy this script to shared location and 
# run this script on nodes with pdsh: 
### pdsh /share/installs/ifup_ib0_nodes.sh


cp /share/installs/ifcfg-ib0 /etc/sysconfig/network-scripts/

my_eth_ip=$(ip route get 8.8.8.8| grep src | sed 's/.*src \(.*\)$/\1/g')

N=${my_eth_ip##*.}

my_ib_ip="172.16.1.$N"

echo "IPADDR=$my_ib_ip" >> /etc/sysconfig/network-scripts/ifcfg-ib0

ifdown ib0
ifup ib0

ssh 172.16.0.1 "echo $my_ib_ip	$HOSTNAME-ib0 >> /etc/hosts"

