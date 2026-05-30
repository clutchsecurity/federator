# AWS to Snowflake

## Setup

Ensure you are logged into both AWS & Snowflake systems from your CLI before executing below terraform commands.

### Verify AWS

```
aws sts get-caller-identity
```

### Verify Snowflake

The Snowflake Terraform provider authenticates via environment variables. Set the following before running Terraform:

```
export SNOWFLAKE_ACCOUNT=<your_account_identifier>
export SNOWFLAKE_USER=<your_admin_user>
export SNOWFLAKE_PASSWORD=<your_password>
```

If your admin user authenticates via SSO, use browser-based authentication instead of a password:

```
export SNOWFLAKE_ACCOUNT=<your_account_identifier>
export SNOWFLAKE_USER=<your_admin_user>
export SNOWFLAKE_AUTHENTICATOR=EXTERNALBROWSER
```

The admin user must have privileges to create users (`USERADMIN` role or equivalent).

### Integration

Connect to Snowflake from AWS Cloud. In this example, we will use an AWS VM to connect to Snowflake using workload identity federation (no passwords or key pairs).

```
terraform init
terraform plan -var snowflake_account=<YOUR_ACCOUNT>
terraform apply -var snowflake_account=<YOUR_ACCOUNT>
```

Optionally pass a warehouse:

```
terraform apply -var snowflake_account=<YOUR_ACCOUNT> -var snowflake_warehouse=<YOUR_WAREHOUSE>
```

Post `terraform apply`, copy the ssh command from the output and login to the AWS VM.

1. Some pre-requisites will be installed
2. Connectivity to Snowflake will be established via workload identity
3. Test it by running: `python3 /tmp/snowflake_wif_demo.py`

### Destroy resources

```
terraform destroy -var snowflake_account=<YOUR_ACCOUNT>
```

## Reference

- [Snowflake Workload Identity Federation](https://docs.snowflake.com/en/user-guide/workload-identity-federation#configure-aws)
