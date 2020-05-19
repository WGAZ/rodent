wg-quick up wg0

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
