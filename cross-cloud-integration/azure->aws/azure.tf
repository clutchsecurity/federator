# Retrieve current Azure AD client configuration, useful for establishing cross-service trust relationships.
data "azuread_client_config" "current" {}

# Define an Azure AD application to be used with AWS resources for trust and authentication.
resource "azuread_application" "demo" {
  depends_on = [
    random_string.random_suffix,
  ]
  display_name     = "${var.prefix}-Application-${random_string.random_suffix.result}"
  description      = "${var.prefix} application description"
  sign_in_audience = "AzureADMyOrg"
  identifier_uris  = ["urn://azure-aws"]
  
  # Define an application role for AWS STS Web Identity API.
  app_role {
    id                   = uuidv5("url", var.app_role)
    value                = var.app_role
    description          = "${var.prefix} - This app will temporarily use AWS STS Web Identity API"
    display_name         = "AssumeRole"
    allowed_member_types = ["User", "Application"]
    enabled              = true
  }
}

# Create a service principal for the above Azure AD application, tagging it for specific integrations.
resource "azuread_service_principal" "demo" {
  depends_on = [ azuread_application.demo ]
  client_id = azuread_application.demo.client_id
  tags      = ["WindowsAzureActiveDirectoryIntegratedApp", "HideApp"]
}

# Set up an Azure Resource Group in the East US region.
resource "azurerm_resource_group" "demo" {
  depends_on = [ random_string.random_suffix ]
  name     = "${var.prefix}-resource-group-${random_string.random_suffix.result}"
  location = "East US"
}

# Define a user-assigned identity in Azure for fine-grained access control within Azure resources.
resource "azurerm_user_assigned_identity" "demo" {
  depends_on = [
    random_string.random_suffix,
    azurerm_resource_group.demo,
  ]
  name                = "${var.prefix}-identity-${random_string.random_suffix.result}"
  resource_group_name = azurerm_resource_group.demo.name
  location            = azurerm_resource_group.demo.location
}

# Assign the defined app role to the user-assigned identity for the specified service principal.
resource "azuread_app_role_assignment" "demo" {
  depends_on = [
    azuread_application.demo,
    azurerm_user_assigned_identity.demo,
    azuread_service_principal.demo,
  ]
  app_role_id         = azuread_application.demo.app_role_ids[var.app_role]
  principal_object_id = azurerm_user_assigned_identity.demo.principal_id
  resource_object_id  = azuread_service_principal.demo.object_id
}
