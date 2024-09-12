# Terraform configuration block specifying required providers and their versions
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "5.29.1"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "4.0.5"
    }
    local = {
      source  = "hashicorp/local"
      version = "2.5.1"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.6.2"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "5.50.0"
    }
  }
}

# Configuration for the Local provider, typically used for managing local files
provider "local" {
  # No specific configurations are necessary here.
}

# Configuration for the AWS provider, used for managing AWS resources
provider "aws" {
  # Region or other configurations can be added here if needed.
}

# Configuration for the Google Cloud provider, including specifying the project
provider "google" {
  project = var.gcp_project_name  # Dynamic assignment of the Google Cloud project from a variable
}