#!/bin/bash
set -e

NETWORK_NAME="infra"
SERVICE_NAME="postgres"

echo "🔍 Checking if the '$NETWORK_NAME' Docker network exists..."
if ! docker network inspect "$NETWORK_NAME" >/dev/null 2>&1; then
  echo "🌐 Creating Docker network '$NETWORK_NAME'..."
  docker network create "$NETWORK_NAME"
else
  echo "✅ Network '$NETWORK_NAME' already exists."
fi

echo "📦 Starting PostgreSQL container..."
docker compose up -d $SERVICE_NAME

echo "🚀 PostgreSQL is starting up..."
docker ps --filter "name=${SERVICE_NAME}"

echo "💡 Tip: to view PostgreSQL logs, run:"
echo "   docker logs postgres_server"