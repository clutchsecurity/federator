terraform {
  required_providers {
    idpfingerprint = {
      source = "thelocalhost.com/terraform-custom-provider/idpfingerprint"
    }
    github = {
      source  = "integrations/github"
      version = "6.2.1"
    }
    aws = {
        source = "hashicorp/aws"
        version = "5.49.0"
    }
    random = {
        source = "hashicorp/random"
        version = "3.6.1"
    }
  }
}

provider "github" {
  token = var.github_pat
  owner = var.github_username
  # organization = 
}