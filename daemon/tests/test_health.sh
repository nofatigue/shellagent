#!/bin/bash
set -e

echo "Testing daemon health..."

# Check if daemon is running
response=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:5738/health)

if [ "$response" = "200" ]; then
    echo "✅ Health check passed"
    
    # Get detailed health info
    health_data=$(curl -s http://localhost:5738/health)
    echo "   Status: $(echo $health_data | jq -r '.status')"
    echo "   Provider: $(echo $health_data | jq -r '.provider')"
    echo "   Model: $(echo $health_data | jq -r '.model')"
    exit 0
else
    echo "❌ Health check failed (HTTP $response)"
    exit 1
fi
