variable "openid_connect_url" {
  type      = string
  default = "https://token.actions.githubusercontent.com"
  nullable = false
}

variable "github_username" {
  type = string
  validation {
    condition     = can(regex("^[a-zA-Z0-9]+$", var.github_username))
    error_message = "The github username must be alphanumeric and contain no special characters"
  }
    validation {
    condition     = length(var.github_username) > 0
    error_message = "The github_username cannot be empty"
  }
  nullable = false
}

variable "github_repo_name" {
  type = string
  validation {
    condition     = length(var.github_repo_name) > 0
    error_message = "The github_repo_name cannot be empty"
  }
  nullable = false
}

variable "github_pat" {
  type = string
  validation {
    condition     = length(var.github_pat) > 0
    error_message = "The github_pat cannot be empty"
  }
  sensitive = true
}

variable "gcp_project" {
  type = string
  validation {
    condition     = length(var.gcp_project) > 0
    error_message = "The gcp_project cannot be empty"
  }
  nullable = false
}