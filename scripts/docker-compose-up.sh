#!/bin/bash
set -e

echo "Starting AutoQuantum OpenCode server in background..."
docker-compose up -d
echo "Server started. Use './scripts/docker-compose-connect.sh' to connect."
echo "Check status with: docker-compose ps"
echo "View logs with: docker-compose logs -f"