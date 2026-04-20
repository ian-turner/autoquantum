#!/bin/bash
set -e

echo "Building AutoQuantum OpenCode Docker image..."
docker-compose build "$@"
echo "Image built: opencode-autoquantum:latest"