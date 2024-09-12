terraform {
  required_providers {
    azuread = {
      source = "hashicorp/azuread"
      version = "2.50.0"
    }
    aws = {
      source = "hashicorp/aws"
      version = "5.50.0"
    }
    tls = {
      source = "hashicorp/tls"
      version = "4.0.5"
    }
    azurerm = {
      source = "hashicorp/azurerm"
      version = "3.104.2"
    }
    random = {
      source = "hashicorp/random"
      version = "3.6.2"
    }
  }
}

# Configure the Azure AD provider with default settings.
provider "azuread" {}

# Initialize the Azure RM (Resource Manager) provider with no specific features enabled.
provider "azurerm" {
  features {}
}
