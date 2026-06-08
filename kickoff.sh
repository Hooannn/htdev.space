#!/bin/bash

echo "Warning: This script currently target on Debian, on another os it might break"

set -e

echo "=================================================="
# DEBIAN_FRONTEND=noninteractive
echo "1. Updating system packages..."
sudo apt update && sudo apt upgrade -y

echo "2. Installing essential utilities (Neovim, Curl, Git...)"
sudo apt install -y neovim curl git wget software-properties-common apt-transport-https ca-certificates gnupg lsb-release htop

echo "3. Installing Docker & Docker Compose..."
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
sudo tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/debian
Suites: $(. /etc/os-release && echo "$VERSION_CODENAME")
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF

sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

sudo systemctl enable docker
sudo systemctl start docker

echo "4. Running post-install docker script"
sudo usermod -aG docker $USER

#Many modern Linux distributions use systemd to manage which services start when
#the system boots. On Debian and Ubuntu, the Docker service starts on boot by default.
#To automatically start Docker and containerd on boot for other Linux distributions using systemd,
#run the following commands:

#sudo systemctl enable docker.service
#sudo systemctl enable containerd.service

echo "=================================================="
echo " VPS Setup Completed Successfully!"
echo " Docker version: $(docker --version)"
echo "=================================================="
