#!/bin/bash

echo "# Installing Wireguard"

./remove.sh

./azure_wg0.sh

./wg1.sh

./Quagga.sh

./Public_IP_Interfaces.sh

./azure_tuninfo.sh

echo "# Cross Cloud installed. To add more clients run cd /etc/scripts ./extraclients.sh"
