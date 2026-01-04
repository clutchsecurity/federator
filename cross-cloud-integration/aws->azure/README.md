# AWS to Azure

## Demo

[![asciicast](https://asciinema.org/a/xkGc0uKb2Hu5YtKIoa8AYphAa.svg)](https://asciinema.org/a/xkGc0uKb2Hu5YtKIoa8AYphAa)

## Setup

Ensure you are logged into both AWS & Azure systems from your CLI before executing below terraform commands.

### Verify AWS

```
aws sts get-caller-identity
```

### Verify Azure

```
az account show
```

### Integration

Connect to Azure systems from AWS Cloud. In this example, we will use AWS VM to connect with Azure resources.

```
terraform init
terraform plan
terraform apply
```

Post `terraform apply`, copy the ssh command from the output and login to the AWS VM.

1. Some pre-requisities will be installed
2. Connectivity to the Azure systems will be established
3. Test it by running the command shown.

### Destroy resources

```
terraform destroy
```
