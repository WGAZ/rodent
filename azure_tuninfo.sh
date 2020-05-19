cd /etc/wireguard/clients2/CLIENT
qrencode -t ansiutf8 < ./CLIENT.conf

# Show config file
echo "####### This is for your Client (WG1 Tunnel) either scan the above QR with the phone app or Copy the text below to your clients config file wg1.conf ##########"
cat ./CLIENT.conf
echo " "
echo " "
echo " "
echo " "
echo " "
echo " "

cd /etc/wireguard/clients/CROSS_CLOUD_SERVER

echo "############ This is for your cross cloud (WG0 Tunnel) Paste the below into your cross cloud server as per readme.docx (cd /etc/scripts nano wg0.conf)##################"
cat ./CROSS_CLOUD_SERVER.conf

echo " "
echo " "
echo " "
echo " "
echo " "
