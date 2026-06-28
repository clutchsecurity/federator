# AWS to Databricks

## Setup

### Prerequisites

1. **AWS CLI** - Ensure you are logged into AWS from your CLI
2. **Databricks Account Console** - You need account admin access to configure service principal federation policies
3. **Databricks CLI** - Install and configure the [Databricks CLI](https://docs.databricks.com/dev-tools/cli/install.html) for account-level operations

### Verify AWS

```
aws sts get-caller-identity
```

### Configure Databricks Workload Identity Federation

Before running Terraform, you must configure the Databricks side via the Account Console and CLI.

1. **Enable Outbound Federation in AWS**

   If not already enabled, note the issuer URL returned:
   ```
   aws iam enable-outbound-web-identity-federation
   ```

   Retrieve the issuer URL:
   ```
   python3 -c "import boto3; print(boto3.client('iam').get_outbound_web_identity_federation_info())"
   ```

2. **Create a Service Principal in Databricks**

   Go to the [Databricks Account Console](https://accounts.cloud.databricks.com/) > Settings > Service Principals > Add Service Principal:
   - Provide a name (e.g., `aws-wif-service-principal`)
   - Add the service principal to your target workspace

   Note the **Application ID** (UUID) — this is the Client ID.

3. **Create a Federation Policy on the Service Principal**

   Use the Databricks CLI to create a federation policy:
   ```
   databricks account service-principal-federation-policy create <SERVICE_PRINCIPAL_ID> --json '{
     "oidc_policy": {
       "issuer": "<AWS_ISSUER_URL>",
       "audiences": ["databricks"],
       "subject": "<IAM_ROLE_ARN>"
     }
   }'
   ```

   - **issuer**: Your AWS account's issuer URL (from step 1 or from Terraform output `aws_issuer_identifier`)
   - **audiences**: `["databricks"]`
   - **subject**: The IAM role ARN (from Terraform output `aws_federation_role_arn`)

4. Note down the following for use as Terraform variables:
   - **Databricks Host**: Your workspace URL (e.g., `https://my-workspace.cloud.databricks.com`)
   - **Client ID**: The service principal's Application ID (UUID, e.g., `a1b2c3d4-e5f6-7890-abcd-ef1234567890`)

### Integration

Connect to Databricks from AWS Cloud. In this example, we will use an AWS VM to call the Databricks API using workload identity federation (no long-lived tokens).

```
terraform init
terraform plan -var databricks_host=<WORKSPACE_URL> -var databricks_client_id=<CLIENT_ID>
terraform apply -var databricks_host=<WORKSPACE_URL> -var databricks_client_id=<CLIENT_ID>
```

Post `terraform apply`, copy the ssh command from the output and login to the AWS VM.

1. Some pre-requisites will be installed
2. AWS web identity token will be obtained
3. Test it by running: `python3 /tmp/databricks_wif_demo.py`

### Destroy resources

```
terraform destroy -var databricks_host=<WORKSPACE_URL> -var databricks_client_id=<CLIENT_ID>
```

## Reference

- [Databricks AWS IAM Workload Identity Federation](https://docs.databricks.com/aws/en/dev-tools/auth/provider-aws-iam)
