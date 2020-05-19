Eth0_IP=$(ifconfig eth0 | sed -En -e 's/.*inet ([0-9.]+).*/\1/p')
echo $Eth0_IP > ./Eth0_IP.var
Eth0_DG=$(/sbin/ip route |grep '^default' | awk '/eth0/ {print $3}')
echo $Eth0_DG > ./Eth0_DG.var
Eth1_IP=$(ifconfig eth1 | sed -En -e 's/.*inet ([0-9.]+).*/\1/p')
echo $Eth1_IP > ./Eth1_IP.var
str="$Eth1_IP"
Eth1_DG=$(awk -F"." '{print $1"."$2"."$3".1"}'<<<$str)
echo $Eth1_DG > ./Eth1_DG.var

#navigate to netplan to configure the interfaces
cd /etc/netplan

cat > ./51-eth0.yaml << EOF
network:
  version: 2
  renderer: networkd
  ethernets:
    eth0:
      addresses:
       - $Eth0_IP/24
      dhcp4: no
      gateway4: $Eth0_DG
      nameservers:
          addresses: [8.8.8.8]
      routes:
       - to: 0.0.0.0/0
         via: $Eth0_DG # Default gateway
         table: 1000
       - to: $Eth0_IP
         via: 0.0.0.0
         scope: link
         table: 1000
      routing-policy:
        - from: $Eth0_IP
          table: 1000
EOF


cat > ./51-eth1.yaml << EOF

network:
  version: 2
  renderer: networkd
  ethernets:
    eth1:
      addresses:
       - $Eth1_IP/24
      dhcp4: no
      gateway4: $Eth1_DG
      nameservers:
          addresses: [8.8.8.8]
      routes:
       - to: 0.0.0.0/0
         via: $Eth1_DG # Default gateway
         table: 2000
       - to: $Eth1_IP
         via: 0.0.0.0
         scope: link
         table: 2000
      routing-policy:
        - from: $Eth1_IP
          table: 2000
EOF

netplan apply 
