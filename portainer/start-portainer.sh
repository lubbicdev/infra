#!/bin/bash

echo "🚀 Installing Portainer..."

# Check if Docker is installed
if ! command -v docker &> /dev/null
then
  echo "❌ Docker not found. Please install it first."
  exit 1
fi

# Create volume (if it doesn't exist)
echo "📦 Creating volume..."
docker volume create portainer_data >/dev/null 2>&1

# Remove old container if it exists
if [ "$(docker ps -aq -f name=portainer)" ]; then
  echo "⚠️ Removing existing Portainer container..."
  docker stop portainer
  docker rm portainer
fi

# Run Portainer
echo "🔥 Starting Portainer..."
docker run -d \
  -p 9443:9443 \
  --name portainer \
  --restart=always \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v portainer_data:/data \
  portainer/portainer-ce:latest

echo "✅ Portainer installed successfully!"
echo "🌐 Access: https://portainer.lubpicking.com.br"