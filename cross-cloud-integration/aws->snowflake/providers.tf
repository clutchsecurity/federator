# Define Terraform settings and specify required providers with versions
terraform {
  required_providers {
    # Local provider for managing local files and directories
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5.1"
    }
    # AWS provider to manage Amazon Web Services resources
    # Version 6.26+ required for aws_iam_outbound_web_identity_federation resource
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.26.0"
    }
    # Snowflake provider to manage Snowflake resources
    snowflake = {
      source  = "Snowflake-Labs/snowflake"
      version = "~> 0.99"
    }
    # Random provider for generating random values
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6.2"
    }
    # TLS provider for managing TLS certificates
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0.5"
    }
  }
}

# AWS provider configuration
provider "aws" {
  region = var.aws_ec2_region
}

# AWS provider configuration with an alias for EC2 specific operations
provider "aws" {
  region = var.aws_ec2_region
  alias  = "ec2-region"
}

# Snowflake provider configuration
# Authentication is configured via environment variables:
# SNOWFLAKE_ACCOUNT, SNOWFLAKE_USER, SNOWFLAKE_PASSWORD (or other auth methods)
provider "snowflake" {}

# Local provider configuration
provider "local" {
  # This provider is used for managing local state files and directories
}
