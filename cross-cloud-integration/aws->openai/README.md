# AWS to OpenAI

## Setup

### Prerequisites

1. **AWS CLI** - Ensure you are logged into AWS from your CLI
2. **OpenAI Dashboard** - You need access to the OpenAI platform to configure Workload Identity

### Verify AWS

```
aws sts get-caller-identity
```

### Configure OpenAI Workload Identity

Before running Terraform, you must configure the OpenAI side via the dashboard:

1. **Enable Outbound Federation in AWS**

   If not already enabled, note the issuer URL returned:
   ```
   aws iam enable-outbound-web-identity-federation
   ```

2. **Create a Workload Identity Provider in OpenAI**

   Go to [OpenAI Dashboard](https://platform.openai.com/) > Settings > Workload Identity:
   - Set **OIDC Issuer URL** to your AWS account's issuer URL (from step 1 or from Terraform output `aws_issuer_identifier`)
   - Set **Audience** to `https://api.openai.com/v1`

3. **Create a Service Account Mapping**

   Map the AWS IAM role to an OpenAI service account:
   - **Key**: `sub`
   - **Value**: The IAM role ARN (from Terraform output `aws_federation_role_arn`)
   - Select the target OpenAI service account

4. Note down the **Identity Provider ID** and **Service Account ID** for use as Terraform variables:
   - Identity Provider ID starts with `idp_` (e.g., `idp_2xRtKp9Vm4Lw7NcQj5Yf3Z8e`)
   - Service Account ID starts with `user-` (e.g., `user-9PmHnD4kXs1RvWcEa7Jq2T6y`)

### Integration

Connect to OpenAI API from AWS Cloud. In this example, we will use an AWS VM to call OpenAI using workload identity federation (no API keys).

```
terraform init
terraform plan -var openai_identity_provider_id=<YOUR_PROVIDER_ID> -var openai_service_account_id=<YOUR_SERVICE_ACCOUNT_ID>
terraform apply -var openai_identity_provider_id=<YOUR_PROVIDER_ID> -var openai_service_account_id=<YOUR_SERVICE_ACCOUNT_ID>
```

Post `terraform apply`, copy the ssh command from the output and login to the AWS VM.

1. Some pre-requisites will be installed
2. AWS web identity token will be obtained
3. Test it by running: `python3 /tmp/openai_wif_demo.py`

### Destroy resources

```
terraform destroy -var openai_identity_provider_id=<YOUR_PROVIDER_ID> -var openai_service_account_id=<YOUR_SERVICE_ACCOUNT_ID>
```

## Reference

- [OpenAI Workload Identity Federation - AWS](https://developers.openai.com/api/docs/guides/workload-identity-federation/aws?lang=python&aws-scenario=outbound)
