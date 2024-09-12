# Retrieve the configuration of the current Azure AD client
data "azuread_client_config" "current" {
}

# Create an Azure AD application with configurable display properties and roles
resource "azuread_application" "demo" {
  display_name     = "${var.prefix}-application-${random_string.random_suffix.result}"
  description      = "${var.prefix} application description ${random_string.random_suffix.result}"
  sign_in_audience = "AzureADMyOrg"

  # Define a custom URI identifier
  identifier_uris = [
    "urn://azure-gcp"
  ]

  # Configure an application role for access management
  app_role {
    id                   = uuidv5("url", var.prefix)
    value                = var.prefix
    description          = "${var.prefix} app_role description ${random_string.random_suffix.result}"
    display_name         = "Connect-To-GCP"
    allowed_member_types = ["User", "Application"]
    enabled              = true
  }
}

# Create a service principal for the Azure AD application
resource "azuread_service_principal" "demo" {
  depends_on = [azuread_application.demo]
  client_id  = azuread_application.demo.client_id

  # Define tags to manage the visibility and integration settings of the service principal
  tags = [
    "WindowsAzureActiveDirectoryIntegratedApp",
    "HideApp",
  ]
}

# Provision an Azure resource group in the specified location
resource "azurerm_resource_group" "demo" {
  name     = "${var.prefix}-resources-${random_string.random_suffix.result}"
  location = "East US"
}

# Create a user-assigned managed identity within the provisioned resource group
resource "azurerm_user_assigned_identity" "demo" {
  depends_on          = [azurerm_resource_group.demo]
  name                = "${var.prefix}-identity-${random_string.random_suffix.result}"
  resource_group_name = azurerm_resource_group.demo.name
  location            = azurerm_resource_group.demo.location
}

# Retrieve a TLS certificate from Azure AD's well-known configuration URL
data "tls_certificate" "azure" {
  url = "https://sts.windows.net/${data.azuread_client_config.current.tenant_id}/.well-known/openid-configuration"
}
