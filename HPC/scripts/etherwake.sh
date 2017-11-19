#!/bin/bash
# useage: ./etherwake.sh <internal_eth_dev>
# e.g. ./etherwake.sh enp8s0f0
# 

eth_int=$1

# after all nodes installed themselves we will have their MACs in /tftpboot/pxelinux.cfg/ folder

for mac in `ls /tftpboot/pxelinux.cfg/01-*`;
do
mac1=`basename $mac`
mac2=${mac1//01-/}
MAC=${mac2//-/:}

echo "awaking $MAC..."
/usr/sbin/ether-wake -i $eth_int $MAC

done;

