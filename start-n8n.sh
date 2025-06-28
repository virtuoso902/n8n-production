#!/bin/bash

# n8n Production Startup Script
# Load environment variables
export $(cat .env | grep -v '^#' | xargs)

# Start n8n server
echo "Starting n8n server..."
echo "Web UI will be available at: http://localhost:${N8N_PORT}"
echo "Default credentials: ${N8N_BASIC_AUTH_USER}"
echo "Please change the default password in .env file"

n8n start