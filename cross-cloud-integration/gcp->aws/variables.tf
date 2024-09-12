# Variable declaration for specifying the Google Cloud project name.
# This variable must be set as it is not nullable, ensuring that a project is always specified.
variable "gcp_project_name" {
  type     = string
  nullable = false  # Ensures that the project name must be provided
}

# Variable declaration for a prefix used to name resources.
# A default value is provided, which can be overridden as needed.
variable "prefix" {
  type    = string
  default = "gcp-to-aws"  # Default prefix used for naming resources, can be overridden
}

# Resource for generating a random string to be used as a suffix in resource names.
# This ensures uniqueness and prevents naming conflicts.
resource "random_string" "random_suffix" {
  length  = 5       # Specifies the length of the random string
  special = false   # Indicates that special characters should not be included
  upper   = false   # Specifies that all characters should be lowercase
}

# Variable for specifying the administrator username for the virtual machine in GCP.
# A default value is provided and the variable is not nullable.
variable "gcp_vm_admin_user" {
  default  = "gcpuser"  # Default username for GCP virtual machine admin
  type     = string
  nullable = false  # Ensures that an admin username must be provided
}
