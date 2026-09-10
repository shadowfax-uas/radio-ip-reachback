#!/bin/bash
exec 2>> pi-setup.log

#####################################
# Suppress all restart prompts globally for this session
export NEEDRESTART_MODE=a
export DEBIAN_FRONTEND=noninteractive
#####################################

# Update/upgrade package lists and turn off prompts
echo "Updating system..."
sudo -E apt-get update -y
sudo -E apt-get dist-upgrade -y \
    -o Dpkg::Options::="--force-confdef" \
    -o Dpkg::Options::="--force-confold"

#####################################
# Install necessary packages
#####################################

echo "Installing packages..."

sudo -E apt install -y \
    nftables \
    curl \
    openssh-server \
    gstreamer1.0-tools \
    gstreamer1.0-plugins-base \
    gstreamer1.0-plugins-good \
    gstreamer1.0-plugins-bad \
    gstreamer1.0-plugins-ugly

#####################################
# Move necessary files
#####################################

echo "Copying files..."

sudo cp -r setup-files/tak /etc/tak
sudo cp setup-files/cot-forwarding.service \
    /etc/systemd/system/cot-forwarding.service

#####################################
# Network configuration
#####################################

echo "Installing network configuration..."

sudo rm -f /etc/nftables.conf
sudo cp setup-files/nftables.conf /etc/nftables.conf

sudo rm -f /etc/netplan/*.yaml
sudo cp setup-files/silvus.yaml /etc/netplan/silvus.yaml

# Activate port forwarding for IPv4
sudo sed -i 's/^# *\(net.ipv4.ip_forward=1\)/\1/' /etc/sysctl.conf

#####################################
# COMPASS video stream configuration
#####################################

UDP_VIDEO_PORT=15004
DEFAULT_RTSP_PORT=554
COMPASS_HOST="compass.mchmr.us"
COMPASS_GROUP="AFCENT"

echo ""
echo "Configure COMPASS video stream"
echo "------------------------------"

####################################
# Script hangs up right here. TODO: find out why
####################################

while true; do
    read -p "Enter aircraft tail number: " AIRCRAFT_TAIL
    AIRCRAFT_TAIL=$(echo "$AIRCRAFT_TAIL" | tr -d '[:space:]')

    if [[ "$AIRCRAFT_TAIL" =~ ^[A-Za-z0-9._-]+$ ]]; then
        break
    else
        echo "Error: tail number must contain only letters, numbers, '.', '_' or '-'."
    fi
done

read -p "Enter COMPASS RTSP port [${DEFAULT_RTSP_PORT}]: " RTSP_PORT
RTSP_PORT=$(echo "$RTSP_PORT" | tr -d '[:space:]')

# Use 554 when no value was entered
RTSP_PORT="${RTSP_PORT:-$DEFAULT_RTSP_PORT}"

if ! [[ "$RTSP_PORT" =~ ^[0-9]+$ ]] || \
    (( RTSP_PORT < 1 || RTSP_PORT > 65535 )); then
    echo "Error: RTSP port must be between 1 and 65535."
    exit 1
fi

RTSP_URL="rtsp://${COMPASS_HOST}:${RTSP_PORT}/${AIRCRAFT_TAIL}/group/${COMPASS_GROUP}"

echo ""
echo "Video stream configuration:"
echo "  Aircraft:     ${AIRCRAFT_TAIL}"
echo "  UDP input:    ${UDP_VIDEO_PORT}"
echo "  COMPASS RTSP: ${RTSP_URL}"
echo ""

#####################################
# Install GStreamer wrapper
#####################################

echo "Installing COMPASS video streaming script..."

sudo tee /usr/local/bin/compass-video-stream.sh > /dev/null <<EOF
#!/bin/bash

exec /usr/bin/gst-launch-1.0 \
    udpsrc port=${UDP_VIDEO_PORT} buffer-size=200000 caps="video/mpegts" \
    ! tsparse parse-private-sections=false \
    ! queue max-size-buffers=10000 max-size-bytes=0 max-size-time=0 leaky=downstream \
    ! tsdemux \
    ! h264parse \
    ! queue \
    ! rtspclientsink protocols=tcp location="${RTSP_URL}"
EOF

sudo chmod +x /usr/local/bin/compass-video-stream.sh

#####################################
# Install GStreamer systemd service
#####################################

echo "Installing COMPASS video streaming service..."

sudo tee /etc/systemd/system/compass-video-stream.service > /dev/null <<EOF
[Unit]
Description=COMPASS Video Stream - ${AIRCRAFT_TAIL}
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=/usr/local/bin/compass-video-stream.sh

Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

#####################################
# Enable local services
#####################################

echo "Enabling services..."

sudo systemctl daemon-reload --no-pager < /dev/null

sudo systemctl enable cot-forwarding.service

sudo systemctl enable nftables
sudo systemctl start nftables

sudo systemctl enable --now ssh
sudo ufw allow ssh

sudo systemctl enable compass-video-stream.service

#####################################
# Connect to ZeroTier
#####################################

echo "Installing ZeroTier..."
curl -s https://install.zerotier.com | sudo bash

echo ""

while true; do
    read -p "Enter the client's ZeroTier Network ID: " ZT_NETWORK_ID
    ZT_NETWORK_ID=$(echo "$ZT_NETWORK_ID" | tr -d '[:space:]')

    if [ -n "$ZT_NETWORK_ID" ]; then
        break
    else
        echo "Error: Network ID cannot be empty."
        echo ""
    fi
done

echo "Attempting to join ZeroTier network: $ZT_NETWORK_ID..."
sudo zerotier-cli join "$ZT_NETWORK_ID"

#####################################
# Finish
#####################################

echo ""
echo "Setup complete."
echo ""
echo "Aircraft:     ${AIRCRAFT_TAIL}"
echo "UDP input:    ${UDP_VIDEO_PORT}"
echo "COMPASS RTSP: ${RTSP_URL}"
echo ""
echo "The system will now reboot."

sudo reboot
