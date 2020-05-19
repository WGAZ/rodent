cd /etc/wireguard/

# We read from the input parameter the name of the client
if [ -z "$1" ]
  then
    read -p "Enter VPN user name: " USERNAME2
    if [ -z $USERNAME2 ]
      then
      echo "[#]Empty VPN user name. Exit"
      exit 1;
    fi
  else USERNAME2=$1
fi

read DNS2 < ./dns2.var
read ENDPOINT2 < ./endpoint2.var
read VPN_SUBNET2 < ./vpn_subnet2.var
PRESHARED_KEY2="_preshared.key2"
PRIV_KEY2="_private.key2"
PUB_KEY2="_public.key2"
ALLOWED_IP2="0.0.0.0/0, ::/0"

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
PublicKey = $SERVER_PUBLIC_KEY_WG1
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

# Show QR config to display
qrencode -t ansiutf8 < ./$USERNAME2.conf

# Show config file
echo "# Display $USERNAME2.conf"
cat ./$USERNAME2.conf

# Save QR config to png file
#qrencode -t png -o ./$USERNAME.png < ./$USERNAME.conf
