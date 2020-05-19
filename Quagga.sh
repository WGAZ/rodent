#Install Quaga on both AWS and Azure Servers

sudo apt install quagga -y
sudo apt install quagga-doc -y

#Copy the configuration files over on both AWS and Azure servers

cp /usr/share/doc/quagga-core/examples/vtysh.conf.sample /etc/quagga/vtysh.conf
cp /usr/share/doc/quagga-core/examples/zebra.conf.sample /etc/quagga/zebra.conf

#Allow the permisions to the files

sudo chown quagga:quagga /etc/quagga/*.conf
sudo chown quagga:quaggavty /etc/quagga/vtysh.conf
sudo chmod 640 /etc/quagga/*.conf

#capture variables
read SERVER_IP < /etc/wireguard/Server_IP.var

#Apply the config
cat >> /etc/quagga/ospfd.conf << EOF

hostname ospf_s1
log file /var/log/quagga/ospfd.log
router ospf
 ospf router-id 1.1.1.1
 redistribute connected
 network $SERVER_IP/24 area 0.0.0.0
access-list localhost permit 127.0.0.1/32
access-list localhost deny any

EOF

#start the services
sudo service zebra start
sudo service ospfd start

#sudo vtysh
#show ip ospf neighbour
#You should have a peer. If not check that MCast traffic is enabled on the WG tunnels (224.0.0.0/8)
#Exit to go back to ubuntu route. 
#You should have full conectivity to every tunnel IP address from all 4 Instances. 
