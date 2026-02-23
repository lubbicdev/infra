#!/bin/bash
set -e

echo "🐳 Installing Docker and Docker Compose on Ubuntu..."

# Update system
echo "📦 Updating system packages..."
apt update -y && apt upgrade -y

# Install dependencies
echo "⚙️ Installing dependencies..."
apt install -y ca-certificates curl gnupg lsb-release

# Add Docker’s official GPG key
echo "🔑 Adding Docker’s official GPG key..."
mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Set up the repository
echo "📂 Adding Docker repository..."
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker Engine
echo "🚀 Installing Docker Engine and Docker Compose plugin..."
apt update -y
apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Enable Docker on boot
echo "🔁 Enabling Docker service..."
systemctl enable docker
systemctl start docker

# Add current user to Docker group (optional)
if [ "$SUDO_USER" ]; then
  echo "👤 Adding $SUDO_USER to Docker group..."
  usermod -aG docker "$SUDO_USER"
  echo "⚠️  Log out and log in again (or run 'newgrp docker') to use Docker without sudo."
fi

# Test installation
echo "🧪 Testing Docker installation..."
docker version && docker compose version

echo "✅ Docker and Docker Compose installation completed successfully!"
echo "✨ You can now run containers normally, e.g.:  docker run hello-world"
