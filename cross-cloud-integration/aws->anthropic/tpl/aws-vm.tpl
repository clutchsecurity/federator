#!/bin/bash
cat <<'EOF' > /etc/profile.d/set_env_vars.sh
#!/bin/bash

echo "Installing prerequisites..."
sudo apt update
sudo apt install -yyq jq unzip python3 python3-pip
curl "https://awscli.amazonaws.com/awscli-exe-linux-aarch64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

pip3 install --user --upgrade boto3 botocore --break-system-packages
pip3 install --user anthropic --break-system-packages

echo "=============================================="
echo "AWS to Anthropic Federation using Outbound Identity Federation"
echo "=============================================="

# Set environment variables for the Anthropic SDK
export AWS_REGION="${aws_region}"
export ANTHROPIC_FEDERATION_RULE_ID="${anthropic_federation_rule_id}"
export ANTHROPIC_ORGANIZATION_ID="${anthropic_organization_id}"
export ANTHROPIC_SERVICE_ACCOUNT_ID="${anthropic_service_account_id}"
export ANTHROPIC_WORKSPACE_ID="${anthropic_workspace_id}"

# Get AWS web identity token using the STS API
echo "Requesting AWS web identity token..."
get_token_output=$(aws sts get-web-identity-token \
  --region $AWS_REGION \
  --audience https://api.anthropic.com \
  --signing-algorithm RS256 \
  --duration-seconds 900)

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

# Create a Python script that uses the Anthropic SDK with workload identity federation
cat <<'PYEOF' > /tmp/anthropic_wif_demo.py
import os
import json
import base64
import boto3
import anthropic
from anthropic import WorkloadIdentityCredentials

FEDERATION_RULE_ID = os.environ["ANTHROPIC_FEDERATION_RULE_ID"]
ORGANIZATION_ID = os.environ["ANTHROPIC_ORGANIZATION_ID"]
SERVICE_ACCOUNT_ID = os.environ["ANTHROPIC_SERVICE_ACCOUNT_ID"]
WORKSPACE_ID = os.environ["ANTHROPIC_WORKSPACE_ID"]
REGION = os.environ["AWS_REGION"]

print("=" * 60)
print("Anthropic WIF Configuration")
print("=" * 60)
print(f"  Federation Rule ID   : {FEDERATION_RULE_ID}")
print(f"  Organization ID      : {ORGANIZATION_ID}")
print(f"  Service Account ID   : {SERVICE_ACCOUNT_ID}")
print(f"  Workspace ID         : {WORKSPACE_ID}")
print(f"  AWS Region           : {REGION}")
print()

def decode_jwt_claims(token):
    """Decode and return the claims from a JWT token (no signature verification)."""
    parts = token.split(".")
    if len(parts) != 3:
        return None
    # Add padding for base64
    payload = parts[1] + "=" * (4 - len(parts[1]) % 4)
    return json.loads(base64.urlsafe_b64decode(payload))

def get_sts_web_identity_token():
    sts = boto3.client("sts", region_name=REGION)
    print("Requesting AWS web identity token via boto3 STS...")
    response = sts.get_web_identity_token(
        Audience=["https://api.anthropic.com"],
        SigningAlgorithm="RS256",
        DurationSeconds=900,
    )
    token = response.get("WebIdentityToken", "")
    if not token:
        raise RuntimeError("AWS STS did not return a web identity token.")

    # Decode and print token claims for debugging
    claims = decode_jwt_claims(token)
    if claims:
        print()
        print("JWT Token Claims:")
        print(f"  iss (issuer)   : {claims.get('iss')}")
        print(f"  sub (subject)  : {claims.get('sub')}")
        print(f"  aud (audience) : {claims.get('aud')}")
        print(f"  exp (expires)  : {claims.get('exp')}")
        print(f"  iat (issued)   : {claims.get('iat')}")
        print()
        print("  Full claims:")
        print(f"  {json.dumps(claims, indent=4)}")
        print()
    else:
        print("  WARNING: Could not decode JWT claims")

    print("Token obtained, passing to Anthropic SDK for exchange...")
    return token

print("Initializing Anthropic client with workload identity...")
client = anthropic.Anthropic(
    credentials=WorkloadIdentityCredentials(
        identity_token_provider=get_sts_web_identity_token,
        federation_rule_id=FEDERATION_RULE_ID,
        organization_id=ORGANIZATION_ID,
        service_account_id=SERVICE_ACCOUNT_ID,
        workspace_id=WORKSPACE_ID,
    ),
)

print("Sending test request to Anthropic API...")
try:
    message = client.messages.create(
        model="claude-sonnet-4-6",
        max_tokens=1024,
        messages=[{"role": "user", "content": "Say hello from AWS outbound workload identity federation."}],
    )
    print()
    print("=" * 60)
    print("SUCCESS! Claude response:")
    print("=" * 60)
    print(message.content[0].text)
except Exception as e:
    print()
    print("=" * 60)
    print(f"FAILED: {type(e).__name__}: {e}")
    print("=" * 60)
    print()
    print("Troubleshooting checklist:")
    print("  1. Does the Issuer URL in Claude Console match the 'iss' claim above?")
    print("  2. Does the Federation Rule audience match the 'aud' claim above?")
    print("  3. Does the Federation Rule subject_prefix match the 'sub' claim above?")
    print(f"     (Expected sub = IAM role ARN)")
    print(f"  4. Is Federation Rule ID correct?   ({FEDERATION_RULE_ID})")
    print(f"  5. Is Organization ID correct?       ({ORGANIZATION_ID})")
    print(f"  6. Is Service Account ID correct?    ({SERVICE_ACCOUNT_ID})")
    print(f"  7. Is Workspace ID correct?          ({WORKSPACE_ID})")
    print(f"  8. Is the service account a member of the workspace?")
    raise
PYEOF

echo "=============================================="
echo "To test Anthropic API access with workload identity federation, run:"
echo "python3 /tmp/anthropic_wif_demo.py"
echo "=============================================="
EOF

chmod +x /etc/profile.d/set_env_vars.sh
