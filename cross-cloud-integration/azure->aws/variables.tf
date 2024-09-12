# Define a variable for specifying an application role, used primarily for identity assumptions.
variable "app_role" {
  type      = string
  default   = "AssumeRoleWithWebIdentity"
  nullable  = false
  description = "The application role name to be used with Web Identity providers."
}

# Define a variable for prefixing resource names to ensure uniqueness and traceability.
variable "prefix" {
  type      = string
  default   = "azure-to-aws"
  nullable  = false
  description = "Prefix for naming resources, used to avoid name clashes and improve manageability."
}

# Generate a random string to append to resources, ensuring unique names and reducing collision risk.
resource "random_string" "random_suffix" {
  length  = 5
  special = false
  upper   = false
}

# Define the username for the Azure virtual machine administrator.
variable "azure_vm_admin_username" {
  type      = string
  default   = "azureuser"
  nullable  = false
  description = "Default username for the administrator account on the Azure VM."
}

# Define the password for the Azure virtual machine administrator, ensuring access credentials are set.
variable "azure_vm_admin_password" {
  type        = string
  default     = "Azureuser1234"
  nullable    = false
  description = "The password for the VM's administrator account."
}
