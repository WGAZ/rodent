#!/bin/bash

cd /etc/wireguard

SERVER_PRIVKEY_WG1=$( wg genkey )
SERVER_PUBKEY_WG1=$( echo $SERVER_PRIVKEY_WG1 | wg pubkey )

echo $SERVER_PUBKEY_WG1 > ./wg1_server_public.key
echo $SERVER_PRIVKEY_WG1 > ./wg1_server_private.key

echo " "
echo " "
echo " "
echo " "
echo " "

read -p "Enter the secondary public ip address / elastic ip (external ip and port) in format [ipv4:port] (e.g. 4.3.2.1:54321):" ENDPOINT2
if [ -z $ENDPOINT2 ]
then
echo "[#]Empty endpoint. Exit"
exit 1;
fi
echo $ENDPOINT2 > ./endpoint2.var

echo " "
echo " "
echo " "
echo " "
echo " "
echo " "

if [ -z "$1" ]
  then
    read -p "Enter WG1 Server Tunnel IP address for the client, [ENTER] set to default: 10.60.0.1: " WG1_SERVER_IP
    if [ -z $WG1_SERVER_IP ]
      then WG1_SERVER_IP="10.50.0.1"
    fi
  else WG1_SERVER_IP=$1
fi

echo $WG1_SERVER_IP | grep -o -E '([0-9]+\.){3}' > ./vpn_subnet2.var

DNS2=$"8.8.8.8"
echo $DNS2 > ./dns2.var
echo 1 > ./last_used_ip2.var

WAN_INTERFACE_NAME_2=$"eth1"
echo $WAN_INTERFACE_NAME_2 > ./wan_interface_name2.var

cat ./endpoint2.var | sed -e "s/:/ /" | while read SERVER_EXTERNAL_IP SERVER_EXTERNAL_PORT_2
do
cat > ./wg1.conf.def << EOF
[Interface]
Address = $WG1_SERVER_IP
SaveConfig = false
PrivateKey = $SERVER_PRIVKEY_WG1
ListenPort = $SERVER_EXTERNAL_PORT_2
PostUp   = iptables -A FORWARD -i %i -j ACCEPT; iptables -A FORWARD -o %i -j ACCEPT; iptables -t nat -A POSTROUTING -o $WAN_INTERFACE_NAME_2 -j MASQUERADE;
PostDown = iptables -D FORWARD -i %i -j ACCEPT; iptables -D FORWARD -o %i -j ACCEPT; iptables -t nat -D POSTROUTING -o $WAN_INTERFACE_NAME_2 -j MASQUERADE;
EOF
done

cp -f ./wg1.conf.def ./wg1.conf

systemctl enable wg-quick@wg1



cd /etc/wireguard/

read DNS2 < ./dns2.var
read ENDPOINT2 < ./endpoint2.var
read VPN_SUBNET2 < ./vpn_subnet2.var
PRESHARED_KEY2="_preshared.key2"
PRIV_KEY2="_private.key2"
PUB_KEY2="_public.key2"
ALLOWED_IP2="0.0.0.0/0, ::/0"

USERNAME2=$"CLIENT"
# Go to the wireguard directory and create a directory structure in which we will store client configuration files
mkdir -p ./clients2
cd ./clients2
mkdir ./$USERNAME2
cd ./$USERNAME2
umask 077

CLIENT_PRESHARED_KEY2=$( wg genpsk )
CLIENT_PRIVKEY2=$( wg genkey )
CLIENT_PUBLIC_KEY2=$( echo $CLIENT_PRIVKEY2 | wg pubkey )

#echo $CLIENT_PRESHARED_KEY2 > ./"$USERNAME$PRESHARED_KEY2"
#echo $CLIENT_PRIVKEY2 > ./"$USERNAME$PRIV_KEY2"
#echo $CLIENT_PUBLIC_KEY2 > ./"$USERNAME$PUB_KEY2"

read WG1_SERVER_PUBLIC_KEY < /etc/wireguard/wg1_server_public.key

# We get the following client IP address
read OCTET_IP2 < /etc/wireguard/last_used_ip2.var
OCTET_IP2=$(($OCTET_IP2+1))
echo $OCTET_IP2 > /etc/wireguard/last_used_ip2.var

CLIENT_IP2="$VPN_SUBNET2$OCTET_IP2/32"
# Create a blank configuration file client
cat > /etc/wireguard/clients2/$USERNAME2/$USERNAME2.conf << EOF
[Interface]
PrivateKey = $CLIENT_PRIVKEY2
Address = $CLIENT_IP2
DNS = $DNS2

[Peer]
PublicKey = $WG1_SERVER_PUBLIC_KEY
PresharedKey = $CLIENT_PRESHARED_KEY2
AllowedIPs = $ALLOWED_IP2
Endpoint = $ENDPOINT2
PersistentKeepalive=25
EOF

# Add new client data to the Wireguard configuration file
cat >> /etc/wireguard/wg1.conf << EOF

[Peer]
PublicKey = $CLIENT_PUBLIC_KEY2
PresharedKey = $CLIENT_PRESHARED_KEY2
AllowedIPs = $CLIENT_IP2
EOF

# Restart Wireguard
systemctl stop wg-quick@wg1
systemctl start wg-quick@wg1
