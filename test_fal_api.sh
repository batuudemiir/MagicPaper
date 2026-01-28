#!/bin/bash

# Test Fal.ai API manually
# Replace REQUEST_ID with actual request ID from console

API_KEY="f811abd1-cc51-4c25-89df-67b0ba81ba40:8b88b0e64cdc64161bbc6957e71e2788"
REQUEST_ID="875f5588-49d9-4839-8cf5-e3b41459356c"  # From your console output

echo "Testing Fal.ai polling endpoints..."
echo ""

# Test 1: With /status
echo "Test 1: Polling with /status"
curl -X GET \
  "https://queue.fal.run/fal-ai/flux/dev/requests/${REQUEST_ID}/status" \
  -H "Authorization: Key ${API_KEY}" \
  -H "Accept: application/json" \
  -v

echo ""
echo "================================"
echo ""

# Test 2: Without /status
echo "Test 2: Polling without /status"
curl -X GET \
  "https://queue.fal.run/fal-ai/flux/dev/requests/${REQUEST_ID}" \
  -H "Authorization: Key ${API_KEY}" \
  -H "Accept: application/json" \
  -v

echo ""
echo "================================"
echo ""

# Test 3: Check Fal.ai documentation endpoint
echo "Test 3: Alternative endpoint format"
curl -X GET \
  "https://fal.run/fal-ai/flux/dev/requests/${REQUEST_ID}" \
  -H "Authorization: Key ${API_KEY}" \
  -H "Accept: application/json" \
  -v
