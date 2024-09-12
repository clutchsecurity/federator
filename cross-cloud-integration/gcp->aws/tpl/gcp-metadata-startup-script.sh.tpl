#!/bin/bash
# Create and write the set_env_vars.sh script to the /etc/profile.d directory
sudo tee /etc/profile.d/set_env_vars.sh << 'EOT'
# Update package listings and install AWS CLI and jq
sudo apt update
sudo apt -y install awscli jq

# Export the AWS IAM Role ARN environment variable for use in the script
export AWS_ROLE_ARN=${aws_iam_role_arn}

# Fetch the Google Cloud identity token for the default service account
token=$(curl -s -H "Metadata-Flavor: Google" "http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/default/identity?format=standard&audience=gcp")

# Use AWS STS to assume the specified role using the fetched token and parse the credentials using jq
response=$(aws sts assume-role-with-web-identity --role-arn "$AWS_ROLE_ARN" --role-session-name "whatever" --web-identity-token "$token" --output json)
export AWS_ACCESS_KEY_ID=$(echo "$response" | jq -r '.Credentials.AccessKeyId')
export AWS_SECRET_ACCESS_KEY=$(echo "$response" | jq -r '.Credentials.SecretAccessKey')
export AWS_SESSION_TOKEN=$(echo "$response" | jq -r '.Credentials.SessionToken')

# Confirmation messages to verify successful configuration
echo "Configured the VM to connect with AWS. To test:"
echo "aws sts get-caller-identity"
aws sts get-caller-identity
EOT

# Make the script executable
chmod +x /etc/profile.d/set_env_vars.sh
