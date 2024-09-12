terraform {
  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = "2.49.0"
    }
    azurerm = {
      source = "hashicorp/azurerm"
      version = "3.103.1"
    }
    github = {
      source  = "integrations/github"
      version = "6.2.1"
    }
    random = {
        source = "hashicorp/random"
        version = "3.6.1"
    }
  }
}

provider "azuread" {}

provider "azurerm" {
  features {}
}

provider "github" {
  token = var.github_pat
  owner = var.github_username
  # organization = 
}
