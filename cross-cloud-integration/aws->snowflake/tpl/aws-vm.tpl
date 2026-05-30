#!/bin/bash
cat <<'EOF' > /etc/profile.d/set_env_vars.sh
#!/bin/bash

echo "Installing prerequisites..."
curl "https://awscli.amazonaws.com/awscli-exe-linux-aarch64.zip" -o "awscliv2.zip"
sudo apt update
sudo apt install -yyq unzip python3 python3-pip
unzip awscliv2.zip
sudo ./aws/install

pip3 install --user --upgrade boto3 botocore --break-system-packages
pip3 install --user "snowflake-connector-python>=4.5.0" --break-system-packages

echo "=============================================="
echo "AWS to Snowflake Federation using Outbound Identity Federation"
echo "=============================================="

# Enable AWS outbound web identity token for Snowflake connector
export SNOWFLAKE_ENABLE_AWS_WIF_OUTBOUND_TOKEN=true

# Create a Python script that connects to Snowflake using workload identity federation
cat <<'PYEOF' > /tmp/snowflake_wif_demo.py
import os
import snowflake.connector

# Enable outbound token support
os.environ["SNOWFLAKE_ENABLE_AWS_WIF_OUTBOUND_TOKEN"] = "true"

conn = snowflake.connector.connect(
    account="${snowflake_account}",
    user="${snowflake_username}",
    authenticator="WORKLOAD_IDENTITY",
    workload_identity_provider="AWS",
    warehouse="${snowflake_warehouse}" if "${snowflake_warehouse}" else None,
)

cursor = conn.cursor()
try:
    cursor.execute("SELECT CURRENT_USER(), CURRENT_ROLE(), CURRENT_ACCOUNT()")
    row = cursor.fetchone()
    print("============================================")
    print("Successfully connected to Snowflake via Workload Identity Federation!")
    print(f"  User:    {row[0]}")
    print(f"  Role:    {row[1]}")
    print(f"  Account: {row[2]}")
    print("============================================")

    cursor.execute("SELECT CURRENT_VERSION()")
    row = cursor.fetchone()
    print(f"  Snowflake Version: {row[0]}")
finally:
    cursor.close()
    conn.close()
PYEOF

echo "=============================================="
echo "To test Snowflake connectivity with workload identity federation, run:"
echo "python3 /tmp/snowflake_wif_demo.py"
echo "=============================================="
EOF

chmod +x /etc/profile.d/set_env_vars.sh
