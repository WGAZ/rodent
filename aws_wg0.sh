#!/bin/bash

apt install net-tools
cd /etc/netplan

cat > ./50-cloud-init.yaml << EOF
network:
    ethernets:
        eth0:
            dhcp4: true
            dhcp6: false
        eth1:
            dhcp4: true
EOF

netplan apply

apt install software-properties-common -y
add-apt-repository ppa:wireguard/wireguard -y
apt update
apt install wireguard-dkms wireguard-tools qrencode -y


NET_FORWARD="net.ipv4.ip_forward=1"
sysctl -w  ${NET_FORWARD}
sed -i "s:#${NET_FORWARD}:${NET_FORWARD}:" /etc/sysctl.conf

cd /etc/scripts
cp wg0.conf /etc/wireguard
cd /etc/wireguard
chmod 777 *
IPmanip=$(fgrep Address ./wg0.conf)
echo $IPmanip |printf '%s\n' "${IPmanip//Address = /}" >./IPmanip.var 
cat ./IPmanip.var |printf '%s\n' "${SERVER_IP///*/}" >./SERVER_IP.var
SERVER_IP=$(cat ./IPmanip.var)
echo $SERVER_IP |printf '%s\n' "${SERVER_IP///*/}" >./Server_IP.var
chmod 777 *

cd /etc/wireguard
systemctl enable wg-quick@wg0
