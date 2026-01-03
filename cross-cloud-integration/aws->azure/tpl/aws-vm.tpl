#!/bin/bash
cat <<'EOF' > /etc/profile.d/set_env_vars.sh
#!/bin/bash

echo "Installing prerequisites..."
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
sudo apt update && sudo apt -y install jq unzip
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

echo "=============================================="
echo "AWS to Azure Federation using Outbound Identity Federation"
echo "=============================================="

# Get AWS web identity token using the new STS API
# This replaces the old Cognito-based approach
echo "Requesting AWS web identity token..."
get_token_output=$(aws sts get-web-identity-token \
  --audience api://AzureADTokenExchange \
  --signing-algorithm RS256 \
  --duration-seconds 300)

echo "Token request completed"

JWT_TOKEN=$(echo $get_token_output | jq -r '.WebIdentityToken')

if [ -z "$JWT_TOKEN" ] || [ "$JWT_TOKEN" == "null" ]; then
  echo "Failed to retrieve JWT_TOKEN"
  exit 1
fi

echo "Successfully obtained AWS web identity token"

# Decode and display token claims (for debugging)
echo "Token claims:"
echo $JWT_TOKEN | jq -R 'split(".") | .[1] | @base64d | fromjson'

# Exchange the AWS token for an Azure access token
echo "Exchanging AWS token for Azure access token..."
output=$(curl -s -X POST 'https://login.microsoftonline.com/${azure_tenant_id}/oauth2/v2.0/token' \
  --header 'Content-Type: application/x-www-form-urlencoded' \
  --data-urlencode "client_id=${azuread_application_demo_client_id}" \
  --data-urlencode 'scope=https://graph.microsoft.com/.default' \
  --data-urlencode 'client_assertion_type=urn:ietf:params:oauth:client-assertion-type:jwt-bearer' \
  --data-urlencode "client_assertion=$JWT_TOKEN" \
  --data-urlencode 'grant_type=client_credentials')

azure_access_token=$(echo $output | jq -r '.access_token')

if [ -z "$azure_access_token" ] || [ "$azure_access_token" == "null" ]; then
  echo "Failed to retrieve Azure access token"
  echo "Error response: $output"
  exit 1
fi

echo "Successfully obtained Azure access token"

# Example: Query Microsoft Graph API
echo "=============================================="
echo "To query Microsoft Graph API, run:"
echo "az rest --method GET --uri \"https://graph.microsoft.com/v1.0/servicePrincipals\" --skip-authorization-header --headers \"Authorization=Bearer \$azure_access_token\""
echo "=============================================="

# Alternative: Use Azure CLI with federated token
echo ""
echo "Alternative: Login with Azure CLI using federated token:"
echo "az login --service-principal --tenant ${azure_tenant_id} --username ${azuread_application_demo_client_id} --federated-token \$JWT_TOKEN"
EOF

chmod +x /etc/profile.d/set_env_vars.sh
