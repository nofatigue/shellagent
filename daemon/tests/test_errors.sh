#!/bin/bash

echo "Testing error handling..."

# Test 1: Invalid JSON
echo "  Test 1: Invalid JSON"
response=$(curl -s -w "\n%{http_code}" -X POST http://localhost:5738/complete \
  -H "Content-Type: application/json" \
  -d 'invalid json')

http_code=$(echo "$response" | tail -n1)
if [ "$http_code" = "400" ] || [ "$http_code" = "422" ]; then
    echo "  ✅ Correctly rejected invalid JSON (HTTP $http_code)"
else
    echo "  ❌ Should reject invalid JSON (got HTTP $http_code)"
fi

# Test 2: Missing required field
echo "  Test 2: Missing prompt field"
response=$(curl -s -w "\n%{http_code}" -X POST http://localhost:5738/complete \
  -H "Content-Type: application/json" \
  -d '{"wrong_field": "value"}')

http_code=$(echo "$response" | tail -n1)
if [ "$http_code" = "400" ] || [ "$http_code" = "422" ]; then
    echo "  ✅ Correctly rejected missing field (HTTP $http_code)"
else
    echo "  ❌ Should reject missing field (got HTTP $http_code)"
fi

# Test 3: Empty prompt
echo "  Test 3: Empty prompt"
response=$(curl -s -w "\n%{http_code}" -X POST http://localhost:5738/complete \
  -H "Content-Type: application/json" \
  -d '{"prompt": ""}')

http_code=$(echo "$response" | tail -n1)
body=$(echo "$response" | head -n -1)

# Should either reject or handle gracefully
if [ "$http_code" = "400" ]; then
    echo "  ✅ Correctly rejected empty prompt (HTTP $http_code)"
elif echo "$body" | jq -e '.error' > /dev/null 2>&1; then
    echo "  ✅ Handled empty prompt with error message"
else
    echo "  ⚠️  Accepted empty prompt (may want to validate)"
fi

# Test 4: Non-existent endpoint
echo "  Test 4: Non-existent endpoint"
response=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:5738/nonexistent)

if [ "$response" = "404" ]; then
    echo "  ✅ Correctly returned 404 for non-existent endpoint"
else
    echo "  ⚠️  Expected 404, got HTTP $response"
fi

echo "✅ Error handling tests completed"
