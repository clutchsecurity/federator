#!/bin/bash
cat <<'EOF' > /etc/profile.d/set_env_vars.sh
#!/bin/bash
echo "Installing some pre-requisites"
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
sudo apt update && sudo apt -y install jq unzip
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

get_token_output=$(aws cognito-identity get-open-id-token-for-developer-identity --identity-pool-id ${identity_pool_id} --logins developerprovidername=developer_provider_value --region us-east-1)
echo "get_token_output: $get_token_output"

JWT_TOKEN=$(echo $get_token_output | jq -r '.Token')
echo "JWT_TOKEN: $JWT_TOKEN"

if [ -z "$JWT_TOKEN" ]; then
  echo "Failed to retrieve JWT_TOKEN"
  exit 1
fi

output=$(curl -X GET 'https://login.microsoftonline.com/${azure_tenant_id}/oauth2/v2.0/token' \
  --header 'Content-Type: application/x-www-form-urlencoded' \
  --data-urlencode "client_id=${azuread_application_demo_client_id}" \
  --data-urlencode 'scope=https://graph.microsoft.com/.default' \
  --data-urlencode 'client_assertion_type=urn:ietf:params:oauth:client-assertion-type:jwt-bearer' \
  --data-urlencode "client_assertion=$JWT_TOKEN" \
  --data-urlencode 'grant_type=client_credentials')
echo "output: $output"

azure_access_token=$(echo $output | jq -r '.access_token')
echo "azure_access_token: $azure_access_token"

if [ -z "$azure_access_token" ]; then
  echo "Failed to retrieve Azure access token"
  exit 1
fi

command_to_run="az rest --method GET --uri \"https://graph.microsoft.com/v1.0/servicePrincipals\" --skip-authorization-header --headers \"Authorization=Bearer \$azure_access_token\""
echo "Run the following command to connect with Azure:"
echo $command_to_run
EOF

chmod +x /etc/profile.d/set_env_vars.sh
