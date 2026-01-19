#!/bin/bash
set -e

echo "Testing /complete endpoint..."

# Test 1: Simple prompt
echo "  Test 1: Simple disk usage prompt"
response=$(curl -s -X POST http://localhost:5738/complete \
  -H "Content-Type: application/json" \
  -d '{"prompt": "show disk usage"}')

# Check if response contains required fields
if echo "$response" | jq -e '.command' > /dev/null && \
   echo "$response" | jq -e '.explanation' > /dev/null; then
    echo "  ✅ Response has required fields"
    command=$(echo "$response" | jq -r '.command')
    echo "     Command: $command"
else
    echo "  ❌ Response missing required fields"
    echo "  Response: $response"
    exit 1
fi

# Test 2: Complex prompt
echo "  Test 2: Complex git prompt"
response=$(curl -s -X POST http://localhost:5738/complete \
  -H "Content-Type: application/json" \
  -d '{"prompt": "create a new git branch called feature/test"}')

if echo "$response" | jq -e '.command' > /dev/null; then
    command=$(echo "$response" | jq -r '.command')
    if [[ "$command" == *"git"* ]]; then
        echo "  ✅ Git command generated correctly"
        echo "     Command: $command"
    else
        echo "  ⚠️  Command doesn't contain 'git': $command"
    fi
else
    echo "  ❌ Failed to generate command"
    exit 1
fi

# Test 3: Context-aware prompt
echo "  Test 3: Context-aware prompt"
response=$(curl -s -X POST http://localhost:5738/complete \
  -H "Content-Type: application/json" \
  -d '{"prompt": "list files", "cwd": "/tmp", "shell": "zsh"}')

if echo "$response" | jq -e '.command' > /dev/null; then
    command=$(echo "$response" | jq -r '.command')
    echo "  ✅ Context-aware command generated"
    echo "     Command: $command"
else
    echo "  ❌ Failed to generate command with context"
    exit 1
fi

echo "✅ All /complete tests passed"
