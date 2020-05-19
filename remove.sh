echo "# Removing"

wg-quick down wg0
systemctl stop wg-quick@wg0
systemctl disable wg-quick@wg0

wg-quick down wg1
systemctl stop wg-quick@wg1
systemctl disable wg-quick@wg1

yes | apt autoremove wireguard wireguard-dkms wireguard-tools
#yes | apt autoremove software-properties-common
yes | apt update

rm -rf /etc/wireguard

sudo apt autoremove quagga -y
sudo apt autoremove quagga-doc -y

echo "# Removed"
