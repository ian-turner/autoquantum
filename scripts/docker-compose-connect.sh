#!/bin/bash
set -e

# Check if OpenCode CLI is installed on the host
if ! command -v opencode &> /dev/null; then
    echo "Error: OpenCode CLI not found on host."
    echo "Install it with: npm install -g @anomalyco/opencode"
    exit 1
fi

echo "Connecting to AutoQuantum OpenCode server at localhost:4096..."
echo "If this is the first connection, you may need to configure a provider."
echo "Press Ctrl+C to exit the TUI; the server will stay running."
echo ""
opencode --hostname localhost --port 4096