#!/bin/bash
set -e

NETWORK_NAME="infra"
SERVICE_NAME="redis"

if [ ! -f ".env" ]; then
  echo "❌ .env file not found. Copy .env.example and fill in the values:"
  echo "   cp .env.example .env && nano .env"
  exit 1
fi

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
