#!/bin/bash

apt install software-properties-common -y
add-apt-repository ppa:wireguard/wireguard -y
apt update
apt install wireguard-dkms wireguard-tools qrencode -y


NET_FORWARD="net.ipv4.ip_forward=1"
sysctl -w  ${NET_FORWARD}
sed -i "s:#${NET_FORWARD}:${NET_FORWARD}:" /etc/sysctl.conf

cd /etc/wireguard

umask 077

SERVER_PRIVKEY=$( wg genkey )
SERVER_PUBKEY=$( echo $SERVER_PRIVKEY | wg pubkey )

echo $SERVER_PUBKEY > ./server_public.key
echo $SERVER_PRIVKEY > ./server_private.key

ENDPOINT=$( dig @resolver1.opendns.com ANY myip.opendns.com +short):443
echo $ENDPOINT > ./endpoint.var
echo " "
echo " "
echo " "
echo " "
echo " "
echo " "
echo " "
if [ -z "$1" ]
  then
    read -p "Enter the WG0 Server Tunnel IP address, [ENTER] set to default: 10.50.0.1: " SERVER_IP
    if [ -z $SERVER_IP ]
      then SERVER_IP="10.50.0.1"
    fi
  else SERVER_IP=$1
fi
echo $SERVER_IP > ./Server_IP.var
echo $SERVER_IP | grep -o -E '([0-9]+\.){3}' > ./vpn_subnet.var


DNS=$"8.8.8.8"
echo $DNS > ./dns.var
echo 1 > ./last_used_ip.var

WAN_INTERFACE_NAME=$"eth0"
echo $WAN_INTERFACE_NAME > ./wan_interface_name.var

cat ./endpoint.var | sed -e "s/:/ /" | while read SERVER_EXTERNAL_IP SERVER_EXTERNAL_PORT
do
cat > ./wg0.conf.def << EOF
[Interface]
Address = $SERVER_IP
SaveConfig = false
PrivateKey = $SERVER_PRIVKEY
ListenPort = $SERVER_EXTERNAL_PORT
PostUp   = iptables -A FORWARD -i %i -j ACCEPT; iptables -A FORWARD -o %i -j ACCEPT; iptables -t nat -A POSTROUTING -o $WAN_INTERFACE_NAME -j MASQUERADE;
PostDown = iptables -D FORWARD -i %i -j ACCEPT; iptables -D FORWARD -o %i -j ACCEPT; iptables -t nat -D POSTROUTING -o $WAN_INTERFACE_NAME -j MASQUERADE;
EOF
done

cp -f ./wg0.conf.def ./wg0.conf

systemctl enable wg-quick@wg0


cd /etc/wireguard/

read DNS < ./dns.var
read ENDPOINT < ./endpoint.var
read VPN_SUBNET < ./vpn_subnet.var
PRESHARED_KEY="_preshared.key"
PRIV_KEY="_private.key"
PUB_KEY="_public.key"

USERNAME=$"CROSS_CLOUD_SERVER"
# Go to the wireguard directory and create a directory structure in which we will store client configuration files
mkdir -p ./clients
cd ./clients
mkdir ./$USERNAME
cd ./$USERNAME
umask 077

CLIENT_PRESHARED_KEY=$( wg genpsk )
CLIENT_PRIVKEY=$( wg genkey )
CLIENT_PUBLIC_KEY=$( echo $CLIENT_PRIVKEY | wg pubkey )

#echo $CLIENT_PRESHARED_KEY > ./"$USERNAME$PRESHARED_KEY"
#echo $CLIENT_PRIVKEY > ./"$USERNAME$PRIV_KEY"
#echo $CLIENT_PUBLIC_KEY > ./"$USERNAME$PUB_KEY"

read SERVER_PUBLIC_KEY < /etc/wireguard/server_public.key

# We get the following client IP address
read OCTET_IP < /etc/wireguard/last_used_ip.var
OCTET_IP=$(($OCTET_IP+1))
echo $OCTET_IP > /etc/wireguard/last_used_ip.var

CLIENT_IP="$VPN_SUBNET$OCTET_IP/24"
# Create a blank configuration file client
cat > /etc/wireguard/clients/$USERNAME/$USERNAME.conf << EOF
[Interface]
PrivateKey = $CLIENT_PRIVKEY
Address = $CLIENT_IP
DNS = $DNS
ListenPort = 443

[Peer]
PublicKey = $SERVER_PUBLIC_KEY
PresharedKey = $CLIENT_PRESHARED_KEY
AllowedIPs = $SERVER_IP, 224.0.0.5, 224.0.0.6
Endpoint = $ENDPOINT
PersistentKeepalive=25
EOF

# Add new client data to the Wireguard configuration file
cat >> /etc/wireguard/wg0.conf << EOF

[Peer]
PublicKey = $CLIENT_PUBLIC_KEY
PresharedKey = $CLIENT_PRESHARED_KEY
AllowedIPs = $CLIENT_IP
EOF

# Restart Wireguard
systemctl stop wg-quick@wg0
systemctl start wg-quick@wg0
