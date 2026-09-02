#!/bin/bash

set -e

CLIENT_ID="6fp2abe5jq2ub27ds0og0gg90p"
REDIRECT_URI="https://example.com/"
GRANT_TYPE="authorization_code"
AUTH_URL="https://production-test-isayen-cloud-design.auth.eu-west-3.amazoncognito.com/oauth2/token"

echo "please visit the following URL to obtain an authorization code:"
echo "https://production-test-isayen-cloud-design.auth.eu-west-3.amazoncognito.com/login?client_id=6fp2abe5jq2ub27ds0og0gg90p&response_type=code&scope=email+openid+profile&redirect_uri=https%3A%2F%2Fexample.com%2F"

read -p "Please enter the authorization code: " CODE

if [ -z "$CODE" ]; then
    echo "Error: Code cannot be empty."
    exit 1
fi

# Envoi de la requête POST
RESPONSE=$(curl -s -X POST "$AUTH_URL" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=${GRANT_TYPE}" \
  -d "client_id=${CLIENT_ID}" \
  -d "code=${CODE}" \
  -d "redirect_uri=${REDIRECT_URI}")

ACCESS_TOKEN=$(echo "$RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin).get('access_token', ''))")

if [ -z "$ACCESS_TOKEN" ]; then
    echo "Error occurred while retrieving the token:"
    echo "$RESPONSE"
    exit 1
fi

# Sauvegarde du token à la racine
echo "$ACCESS_TOKEN" > ./access_token.txt
echo "Access token saved successfully in access_token.txt"