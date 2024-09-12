# Terraform configuration specifying required providers and their versions
terraform {
  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = "2.49.0"  # Specified version to match previously installed version
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.103.1"  # Specified version to match previously installed version
    }
    random = {
      source  = "hashicorp/random"
      version = "3.6.1"  # Specified version to match previously installed version
    }
    tls = {
      source  = "hashicorp/tls"
      version = "4.0.5"  # Latest version used as per previously installed information
    }
    local = {
      source  = "hashicorp/local"
      version = "2.5.1"  # Latest version used as per previously installed information
    }
    google = {
      source  = "hashicorp/google"
      version = "5.31.1"  # Latest version used as per previously installed information
    }
  }
}


# Configuration for the Google Cloud provider
provider "google" {
  project = var.gcp_project_name  # Dynamically assigns the Google Cloud project from a variable
}

# Configuration for the Local provider
provider "local" {
  # This provider manages local files and directories
}

# Azure AD provider configuration
provider "azuread" {
  # Using default configurations, no specific parameters set
}

# Azure RM (Resource Manager) provider configuration
provider "azurerm" {
  features {}  # Required block, even when no features are explicitly enabled
}
