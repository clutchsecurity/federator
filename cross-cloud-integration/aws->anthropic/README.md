# AWS to Anthropic

## Setup

### Prerequisites

1. **AWS CLI** - Ensure you are logged into AWS from your CLI
2. **Claude Console** - You need admin access to your Anthropic organization to configure Workload Identity

### Verify AWS

```
aws sts get-caller-identity
```

### Configure Anthropic Workload Identity

Before running Terraform, you must configure the Anthropic side via the Claude Console.

1. **Enable Outbound Federation in AWS**

   If not already enabled, note the issuer URL returned:
   ```
   aws iam enable-outbound-web-identity-federation
   ```

   Retrieve the issuer URL:
   ```
   python3 -c "import boto3; print(boto3.client('iam').get_outbound_web_identity_federation_info())"
   ```

2. **Register a Federation Issuer in Claude Console**

   Go to [Claude Console](https://console.anthropic.com/) > Settings > Workload Identity > [Issuers](https://platform.claude.com/settings/workload-identity-federation) > Create Issuer:
   - **Name**: e.g., `aws-sts`
   - **Issuer URL**: Your AWS account's issuer URL (from step 1 or from Terraform output `aws_issuer_identifier`)
   - **JWKS source**: `discovery`

   Note the Issuer ID (`fdis_...`).

3. **Create a Service Account**

   Go to Settings > Service Accounts > Create Service Account:
   - Provide a name (e.g., `inference-worker`)
   - Add the service account as a member of the target workspace

   Note the Service Account ID (`svac_...`).

4. **Create a Federation Rule**

   Go to Settings > Workload Identity > Federation Rules > Create Rule:
   - **Issuer**: Select the issuer from step 2
   - **Subject prefix**: The IAM role ARN (from Terraform output `aws_federation_role_arn`)
   - **Audience**: `https://api.anthropic.com`
   - **Target**: The service account from step 3
   - **Workspace**: The workspace the service account is a member of
   - **Token lifetime**: e.g., `600` seconds

   Note the Federation Rule ID (`fdrl_...`).

5. Note down the following IDs for use as Terraform variables:
   - Federation Rule ID starts with `fdrl_` (e.g., `fdrl_3nTqWx8Kp2Rv5YjLm9Df1Z4b`)
   - Organization ID is a UUID (e.g., `a1b2c3d4-e5f6-7890-abcd-ef1234567890`)
   - Service Account ID starts with `svac_` (e.g., `svac_7mHnKp4xRs2Lw9QjDf5Yt3Vb`)
   - Workspace ID starts with `wrkspc_` (e.g., `wrkspc_5kNpRt2Lx8Qw3YjDm7Hf9Vbs`)

### Integration

Connect to Anthropic API from AWS Cloud. In this example, we will use an AWS VM to call the Claude API using workload identity federation (no API keys).

```
terraform init
terraform plan \
  -var anthropic_federation_rule_id=<FEDERATION_RULE_ID> \
  -var anthropic_organization_id=<ORGANIZATION_ID> \
  -var anthropic_service_account_id=<SERVICE_ACCOUNT_ID> \
  -var anthropic_workspace_id=<WORKSPACE_ID>
terraform apply \
  -var anthropic_federation_rule_id=<FEDERATION_RULE_ID> \
  -var anthropic_organization_id=<ORGANIZATION_ID> \
  -var anthropic_service_account_id=<SERVICE_ACCOUNT_ID> \
  -var anthropic_workspace_id=<WORKSPACE_ID>
```

Post `terraform apply`, copy the ssh command from the output and login to the AWS VM.

1. Some pre-requisites will be installed
2. AWS web identity token will be obtained
3. Test it by running: `python3 /tmp/anthropic_wif_demo.py`

### Destroy resources

```
terraform destroy \
  -var anthropic_federation_rule_id=<FEDERATION_RULE_ID> \
  -var anthropic_organization_id=<ORGANIZATION_ID> \
  -var anthropic_service_account_id=<SERVICE_ACCOUNT_ID> \
  -var anthropic_workspace_id=<WORKSPACE_ID>
```

## Reference

- [Anthropic Workload Identity Federation](https://platform.claude.com/docs/en/manage-claude/workload-identity-federation)
- [Anthropic WIF with AWS](https://platform.claude.com/docs/en/manage-claude/wif-providers/aws)
