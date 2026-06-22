#!/bin/bash
exec 2>> pi-setup.log

#####################################
# Suppress all serial restart prompts globally for this session
export NEEDRESTART_MODE=a
export DEBIAN_FRONTEND=noninteractive
#####################################

# Update/upgrade package lists and turn off prompts
echo "Updating system..."
sudo -E apt-get update -y
sudo -E apt-get dist-upgrade -y \
-o Dpkg::Options::="--force-confdef" \
-o Dpkg::Options::="--force-confold"

##################################
# Unused for now but may need if we move setup into GitLab

# Unzip tar file & move into it
# mkdir -p ~/stardogos-main
# tar -xvf ~/stardogos-main.tar
# cd ~/stardogos-main
##################################

# Move necessary files
echo "Copying files..."
sudo cp -r setup-files/tak /etc/tak
sudo cp setup-files/cot-forwarding.service /etc/systemd/system/cot-forwarding.service

# Install necessary packages
sudo -E apt install -y nftables
sudo -E apt install -y curl
sudo -E apt install -y openssh-server

# Swap in our custom files
sudo rm /etc/nftables.conf
sudo cp setup-files/nftables.conf /etc/nftables.conf

sudo rm -f /etc/netplan/*.yaml
sudo cp setup-files/silvus.yaml /etc/netplan/silvus.yaml

# Activate port forwarding for IPv4
sudo sed -i 's/^# *\(net.ipv4.ip_forward=1\)/\1/' /etc/sysctl.conf

# Refresh system and enable service
sudo systemctl daemon-reload --no-pager < /dev/null
sudo systemctl restart cot-forwarding.service
sudo systemctl enable nftables && sudo systemctl start nftables
sudo systemctl enable --now ssh
sudo ufw allow ssh

# Connect to zerotier
curl -s https://install.zerotier.com | sudo bash

echo "Enter ZeroTier Network ID: "

while true; do
    read -p "Enter the client's ZeroTier Network ID: " ZT_NETWORK_ID
    ZT_NETWORK_ID=$(echo "$ZT_NETWORK_ID" | tr -d '[:space:]') # clean input

    if [ -n "$ZT_NETWORK_ID" ]; then
        break # Exit listening loop and connect to network
    else
        echo "Error: Network ID cannot be empty. Please enter Network ID: "
        echo ""
    fi
done

echo "Attempting to join ZeroTier network: $ZT_NETWORK_ID..."
sudo zerotier-cli join "$ZT_NETWORK_ID"

sudo reboot
