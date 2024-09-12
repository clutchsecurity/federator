# Define required Terraform version and provider dependencies
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google" # Google Cloud provider
      version = "5.29.1"
    }
    tls = {
      source  = "hashicorp/tls" # TLS provider for cryptographic functions
      version = "4.0.5"
    }
    local = {
      source  = "hashicorp/local" # Local provider for managing local files
      version = "2.5.1"
    }
    azuread = {
      source  = "hashicorp/azuread" # Azure Active Directory provider
      version = "2.50.0"
    }
    random = {
      source  = "hashicorp/random" # Random provider for generating random values
      version = "3.6.1"
    }
    null = {
      source  = "hashicorp/null" # Null provider for implementing utilities
      version = "3.2.2"
    }
    azurerm = {
      source  = "hashicorp/azurerm" # Azure Resource Manager provider
      version = "3.104.0"
    }
  }
}

# Azure Active Directory Provider configuration
provider "azuread" {
  # No specific configuration options are set here.
}

# Azure Resource Manager Provider configuration
provider "azurerm" {
  # Placeholder for future configurations; currently, no specific features are configured.
  features {}
}

# Local Provider configuration
provider "local" {
  # This provider typically requires no specific configuration.
}

# Google Cloud Provider configuration, setting the project based on input variables
provider "google" {
  project = var.gcp_project_name # Dynamic assignment of the Google Cloud project name
}
