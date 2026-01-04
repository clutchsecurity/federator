# Define Terraform settings and specify required providers with versions
terraform {
  required_providers {
    # Local provider for managing local files and directories
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5.1"
    }
    # Azure Resource Manager provider to manage Azure resources
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.112.0"
    }
    # AWS provider to manage Amazon Web Services resources
    # Version 6.26+ required for aws_iam_outbound_web_identity_federation resource
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.26.0"
    }
    # Azure AD provider to manage Azure Active Directory resources
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.53.1"
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

# Local provider configuration
provider "local" {
  # This provider is used for managing local state files and directories
}

# Azure AD provider configuration
provider "azuread" {
  # This provider is used for managing Azure Active Directory resources
}

# Azure RM provider configuration
provider "azurerm" {
  features {}
}
