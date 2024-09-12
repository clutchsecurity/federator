# Variable declaration for specifying the Google Cloud project name.
# This is a mandatory setting as the variable is not nullable, ensuring that a project name is always provided.
variable "gcp_project_name" {
  type     = string
  nullable = false  # Ensures that the project name is explicitly specified for deployments
}

# Variable for specifying the administrator username for the virtual machine in GCP.
# A default value is provided, and the variable is not nullable to ensure a username is always specified.
variable "gcp_vm_admin_user" {
  default  = "gcpuser"  # Default username for GCP virtual machine admin
  type     = string
  nullable = false  # Prevents omitting the admin username to ensure deployment consistency
}

# Variable declaration for a prefix used to name resources.
# A default value is provided which can be overridden, useful for distinguishing environments or deployments.
variable "prefix" {
  type    = string
  default = "gcp-to-azure"  # Serves as a default prefix for resource naming, can be customized
}

# Resource definition for generating a random string which acts as a suffix for resource names.
# This ensures resource names are unique and avoids naming conflicts across deployments.
resource "random_string" "random_suffix" {
  length  = 5       # Length of the random string
  special = false   # Excludes special characters for simplicity
  upper   = false   # Ensures all characters are lowercase to maintain uniformity
}

# Variable to specify the OpenID Connect issuer URL used for federated identity.
# This setting is crucial for configurations involving identity federation with GCP.
variable "openid_connect_url" {
  type      = string
  default   = "https://accounts.google.com"
  nullable  = false  # Ensures that an issuer URL is always defined
}

# Variable for specifying the location of Azure resource groups.
# A default value is provided, ensuring deployments are consistently located unless overridden.
variable "resource_group_location" {
  type     = string
  default  = "East US"  # Default location for resource groups, can be customized
  nullable = false  # Ensures that a location is always specified for resource groups
}

# Variable for defining an audience URI used in configurations like OAuth2 token issuance.
# This helps in specifying the intended recipient or authorized party for tokens.
variable "audience" {
  default = "urn://gcp-azure"  # Default audience URI for OAuth2 scenarios
  type    = string
}
