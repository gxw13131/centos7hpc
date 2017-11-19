#!/bin/bash
# Execute as ./firewall.sh <eth_internal> <eth_external>
# NAT configuration


if [ $# -eq 0 ]
  then
	eth_ext="enp0s3"
	eth_int="enp0s8"
else

	eth_int=$1
	eth_ext=$2
fi

echo "external eth: $eth_ext"
echo "internal eth: $eth_int"

# exit 0

sysctl -w net.ipv4.ip_forward=1
echo "net.ipv4.ip_forward = 1" > /etc/sysctl.d/ip_forward.conf


firewall-cmd --zone=internal --change-interface=$eth_int
firewall-cmd --zone=external --change-interface=$eth_ext

firewall-cmd --permanent --zone=internal --add-service=tftp
firewall-cmd --permanent --zone=internal --add-service=dns
firewall-cmd --permanent --zone=internal --add-service=http
firewall-cmd --permanent --zone=internal --add-service=nfs
firewall-cmd --permanent --zone=internal --add-service=ssh
#slurm ports
firewall-cmd --permanent --zone=internal --add-port=6817-6818/tcp
#ganglia 
firewall-cmd --permanent --zone=internal --add-port=8649/udp
firewall-cmd --permanent --zone=internal --add-port=8649/tcp
firewall-cmd --permanent --zone=internal --add-port=7321/tcp


firewall-cmd --permanent --zone=external --add-service=ssh
firewall-cmd --permanent --zone=external --add-service=vnc-server
firewall-cmd --permanent --zone=external --add-service=http


firewall-cmd --permanent --direct --passthrough ipv4 -t nat -I POSTROUTING -o $eth_ext -j MASQUERADE -s 172.16.0.0/24
firewall-cmd --permanent --direct --passthrough ipv4 -I FORWARD -i $eth_int -j ACCEPT

firewall-cmd --reload

#systemctl restart network
systemctl restart firewalld
firewall-cmd --get-active-zones
