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
pip3 install --user databricks-sdk --break-system-packages

echo "=============================================="
echo "AWS to Databricks Federation using Outbound Identity Federation"
echo "=============================================="

# Set environment variables for the Databricks SDK
export AWS_REGION="${aws_region}"
export DATABRICKS_HOST="${databricks_host}"
export DATABRICKS_CLIENT_ID="${databricks_client_id}"

# Get AWS web identity token using the STS API
echo "Requesting AWS web identity token..."
get_token_output=$(aws sts get-web-identity-token \
  --region $AWS_REGION \
  --audience databricks \
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

# Create a Python script that uses the Databricks SDK with workload identity federation
cat <<'PYEOF' > /tmp/databricks_wif_demo.py
import os
import json
import base64
import boto3
from databricks.sdk import WorkspaceClient
from databricks.sdk import oidc
from databricks.sdk.core import Config, credentials_strategy, oidc_credentials_provider

DATABRICKS_HOST = os.environ["DATABRICKS_HOST"]
CLIENT_ID = os.environ["DATABRICKS_CLIENT_ID"]
REGION = os.environ["AWS_REGION"]

print("=" * 60)
print("Databricks WIF Configuration")
print("=" * 60)
print(f"  Databricks Host      : {DATABRICKS_HOST}")
print(f"  Client ID            : {CLIENT_ID}")
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

class AwsStsTokenSource(oidc.IdTokenSource):
    """Token source that uses AWS STS to generate web identity tokens for Databricks."""

    def __init__(self, audience="databricks", region="us-east-1"):
        self._audience = audience
        self._region = region

    def id_token(self) -> oidc.IdToken:
        sts = boto3.client("sts", region_name=self._region)
        print("Requesting AWS web identity token via boto3 STS...")
        response = sts.get_web_identity_token(
            Audience=[self._audience],
            SigningAlgorithm="RS256",
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

        print("Token obtained, passing to Databricks SDK for exchange...")
        return oidc.IdToken(jwt=token)

@credentials_strategy("aws-sts-wif", [])
def aws_sts_wif_strategy(cfg: Config):
    return oidc_credentials_provider(cfg, AwsStsTokenSource(region=REGION))

print("Initializing Databricks client with workload identity...")
client = WorkspaceClient(
    host=DATABRICKS_HOST,
    client_id=CLIENT_ID,
    credentials_strategy=aws_sts_wif_strategy,
)

print("Sending test request to Databricks API (listing clusters)...")
try:
    clusters = list(client.clusters.list())
    print()
    print("=" * 60)
    print("SUCCESS! Databricks clusters:")
    print("=" * 60)
    if clusters:
        for c in clusters:
            print(f"  - {c.cluster_name} (state: {c.state})")
    else:
        print("  No clusters found (this is OK - authentication succeeded)")
except Exception as e:
    print()
    print("=" * 60)
    print(f"FAILED: {type(e).__name__}: {e}")
    print("=" * 60)
    print()
    print("Troubleshooting checklist:")
    print("  1. Does the Issuer URL in the federation policy match the 'iss' claim above?")
    print("  2. Does the federation policy audience match the 'aud' claim above?")
    print("  3. Does the federation policy subject match the 'sub' claim above?")
    print(f"     (Expected sub = IAM role ARN)")
    print(f"  4. Is the Databricks Host correct?   ({DATABRICKS_HOST})")
    print(f"  5. Is the Client ID correct?          ({CLIENT_ID})")
    print(f"  6. Does the service principal have workspace access?")
    print(f"  7. Was the federation policy created on the correct service principal?")
    raise
PYEOF

echo "=============================================="
echo "To test Databricks API access with workload identity federation, run:"
echo "python3 /tmp/databricks_wif_demo.py"
echo "=============================================="
EOF

chmod +x /etc/profile.d/set_env_vars.sh
