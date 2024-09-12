terraform {
  required_providers {
    google = {
        source = "hashicorp/google"
        version = "5.28.0"
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

provider "google" {
  project = var.gcp_project
}

provider "github" {
  token = var.github_pat
  owner = var.github_username
  # organization = 
}
