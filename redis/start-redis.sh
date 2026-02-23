#!/bin/bash
set -e

NETWORK_NAME="redis"
SERVICE_NAME="redis"

echo "🔍 Checking if the '$NETWORK_NAME' Docker network exists..."
if ! docker network inspect "$NETWORK_NAME" >/dev/null 2>&1; then
  echo "🌐 Creating Docker network '$NETWORK_NAME'..."
  docker network create "$NETWORK_NAME"
else
  echo "✅ Network '$NETWORK_NAME' already exists."
fi

echo "📦 Starting Redis container..."
docker compose up -d $SERVICE_NAME

echo "🚀 Redis is starting up..."
docker ps --filter "name=${SERVICE_NAME}"

echo "💡 Tip: to view Redis logs, run:"
echo "   docker logs -f ${SERVICE_NAME}"
