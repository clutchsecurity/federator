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
    # External provider for running external programs
    external = {
      source  = "hashicorp/external"
      version = "~> 2.3.3"
    }
    # AWS provider to manage Amazon Web Services resources
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.58.0"
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

# AWS provider configuration for general region
provider "aws" {
  region = var.aws_cognito_region  # Dynamically set the AWS region from variables
}

# AWS provider configuration with an alias for a specific region (EC2 instances)
provider "aws" {
  region = var.aws_ec2_region  # Dynamically set the AWS region for EC2 specific operations
  alias  = "ec2-region"       # Alias used to differentiate this configuration
}

# Local provider configuration
provider "local" {
  # This provider is used for managing local state files and directories
}

# Azure AD provider configuration
provider "azuread" {
  # This provider is used for managing Azure Active Directory resources
  # Default configuration is used, no specific parameters set
}

# Azure RM provider configuration
provider "azurerm" {
  features {}  # Required empty block, needed even when no specific features are configured
}
