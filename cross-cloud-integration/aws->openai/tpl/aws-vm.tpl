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
pip3 install --user openai --break-system-packages

echo "=============================================="
echo "AWS to OpenAI Federation using Outbound Identity Federation"
echo "=============================================="

# Set environment variables for the OpenAI SDK
export AWS_REGION="${aws_region}"
export OPENAI_IDENTITY_PROVIDER_ID="${openai_identity_provider_id}"
export OPENAI_SERVICE_ACCOUNT_ID="${openai_service_account_id}"
export OPENAI_WIF_AUDIENCE="https://api.openai.com/v1"

# Get AWS web identity token using the STS API
echo "Requesting AWS web identity token..."
get_token_output=$(aws sts get-web-identity-token \
  --audience https://api.openai.com/v1 \
  --signing-algorithm ES384 \
  --duration-seconds 300)

echo "Token request completed"

export JWT_TOKEN=$(echo $get_token_output | jq -r '.WebIdentityToken')

if [ -z "$JWT_TOKEN" ] || [ "$JWT_TOKEN" == "null" ]; then
  echo "Failed to retrieve JWT_TOKEN"
  exit 1
fi

echo "Successfully obtained AWS web identity token"

# Decode and display token claims (for debugging)
echo "Token claims:"
echo $JWT_TOKEN | jq -R 'split(".") | .[1] | @base64d | fromjson'

# Create a Python script that uses the OpenAI SDK with workload identity federation
cat <<'PYEOF' > /tmp/openai_wif_demo.py
import os
import json
import base64
import boto3
from openai import OpenAI

IDENTITY_PROVIDER_ID = os.environ["OPENAI_IDENTITY_PROVIDER_ID"]
SERVICE_ACCOUNT_ID = os.environ["OPENAI_SERVICE_ACCOUNT_ID"]
AUDIENCE = os.environ.get("OPENAI_WIF_AUDIENCE", "https://api.openai.com/v1")
REGION = os.environ["AWS_REGION"]

print("=" * 60)
print("OpenAI WIF Configuration")
print("=" * 60)
print(f"  Identity Provider ID : {IDENTITY_PROVIDER_ID}")
print(f"  Service Account ID   : {SERVICE_ACCOUNT_ID}")
print(f"  Audience             : {AUDIENCE}")
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

def aws_outbound_web_identity_token_provider(audience):
    sts = boto3.client("sts", region_name=REGION)

    def get_token():
        print("Requesting AWS web identity token via boto3 STS...")
        response = sts.get_web_identity_token(
            Audience=[audience],
            SigningAlgorithm="ES384",
            DurationSeconds=300,
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

        print("Token obtained, passing to OpenAI SDK for exchange...")
        return token

    return {"token_type": "jwt", "get_token": get_token}

print("Initializing OpenAI client with workload identity...")
client = OpenAI(
    workload_identity={
        "identity_provider_id": IDENTITY_PROVIDER_ID,
        "service_account_id": SERVICE_ACCOUNT_ID,
        "provider": aws_outbound_web_identity_token_provider(AUDIENCE),
    },
)

print("Sending test request to OpenAI API...")
try:
    response = client.responses.create(
        model="gpt-4.1-mini",
        input="Say hello from AWS outbound workload identity federation.",
    )
    print()
    print("=" * 60)
    print("SUCCESS! OpenAI response:")
    print("=" * 60)
    print(response.output_text)
except Exception as e:
    print()
    print("=" * 60)
    print(f"FAILED: {type(e).__name__}: {e}")
    print("=" * 60)
    print()
    print("Troubleshooting checklist:")
    print("  1. Does the OIDC Issuer URL in OpenAI match the 'iss' claim above?")
    print("  2. Does the Audience in OpenAI match the 'aud' claim above?")
    print("  3. Does the Service Account mapping 'sub' value match the 'sub' claim above?")
    print(f"     (Expected sub = IAM role ARN)")
    print(f"  4. Is Identity Provider ID correct? ({IDENTITY_PROVIDER_ID})")
    print(f"  5. Is Service Account ID correct?   ({SERVICE_ACCOUNT_ID})")
    raise
PYEOF

echo "=============================================="
echo "To test OpenAI API access with workload identity federation, run:"
echo "python3 /tmp/openai_wif_demo.py"
echo "=============================================="
EOF

chmod +x /etc/profile.d/set_env_vars.sh
