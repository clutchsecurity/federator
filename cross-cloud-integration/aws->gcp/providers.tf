# Define required providers and their versions for this configuration
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
    null = {
      source  = "hashicorp/null"
      version = "3.2.2"
    }
  }
}

# Configure the Google Cloud provider with the specified project
provider "google" {
  project = var.gcp_project_name
}

# Configure the AWS provider with the specified region
provider "aws" {
  region = var.aws_region
}
