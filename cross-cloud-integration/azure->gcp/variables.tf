# Variable declaration for the Google Cloud project name
# This is crucial for directing where resources should be provisioned within GCP
variable "gcp_project_name" {
  type     = string
  nullable = false # Ensures that a GCP project name must be specified
}

# Variable declaration for a prefix used in naming resources
# This prefix is used to distinguish resources related to the Azure to GCP integration
variable "prefix" {
  type     = string
  default  = "azure-to-gcp" # Default value for the prefix
  nullable = false          # Ensures that the prefix must always have a value
}

# Resource to generate a random string used as a suffix in resource names
# This helps ensure that resource names are unique and avoid conflicts
resource "random_string" "random_suffix" {
  length  = 5     # Length of the random string
  special = false # Exclude special characters to simplify usage
  upper   = false # Use only lowercase letters for consistency
}

# Variable for specifying the default administrator username
# Used in configurations where a username is necessary, like VM provisioning
variable "admin_username" {
  default = "azureuser" # Provides a default username, which can be overridden as needed
}
