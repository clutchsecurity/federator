# Data source to fetch current Azure client configuration
data "azurerm_client_config" "current" {}

# Data resource to fetch published app IDs for known applications (like Microsoft Graph)
data "azuread_application_published_app_ids" "well_known" {}

# Service principal data source for Microsoft Graph
data "azuread_service_principal" "msgraph" {
  client_id = data.azuread_application_published_app_ids.well_known.result.MicrosoftGraph
}

# Fetch all Azure AD service principals
data "azuread_service_principals" "all" {
  return_all = true
}

# Resource to create an Azure AD Application with necessary permissions
resource "azuread_application" "demo" {
  depends_on = [
    random_string.random_suffix,
    data.azuread_application_published_app_ids.well_known,
    data.azuread_service_principal.msgraph,
  ]
  display_name = "${var.prefix} Demo ${random_string.random_suffix.result}"
  sign_in_audience = "AzureADMyOrg"

  # Defining required access to specific Microsoft Graph APIs
  required_resource_access {
    resource_app_id = data.azuread_application_published_app_ids.well_known.result.MicrosoftGraph

    resource_access {
      id   = data.azuread_service_principal.msgraph.app_role_ids["User.Read.All"]
      type = "Role"
    }
    resource_access {
      id   = data.azuread_service_principal.msgraph.app_role_ids["Directory.Read.All"]
      type = "Role"
    }
  }
}

# Resource group in Azure to organize related resources
resource "azurerm_resource_group" "demo" {
  depends_on = [
    random_string.random_suffix,
  ]
  name     = "${var.prefix}-resource-group-${random_string.random_suffix.result}"
  location = var.resource_group_location
}

# Service principal for the Azure AD application
resource "azuread_service_principal" "demo" {
  depends_on = [ azuread_application.demo ]
  client_id = azuread_application.demo.client_id
}

# Role assignment to give the service principal necessary permissions within the resource group
resource "azurerm_role_assignment" "demo" {
  depends_on = [
    azurerm_resource_group.demo,
    azuread_service_principal.demo,
  ]
  scope                = azurerm_resource_group.demo.id
  role_definition_name = "Contributor"
  principal_id         = azuread_service_principal.demo.id
}

# Federated identity credential associated with the Azure AD application
resource "azuread_application_federated_identity_credential" "demo" {
  depends_on = [
    azuread_application.demo,
    azurerm_role_assignment.demo,
    azuread_app_role_assignment.demo,
    random_string.random_suffix,
    google_service_account.demo,
  ]
  display_name   = "${var.prefix}-demo-${random_string.random_suffix.result}"
  application_id = "/applications/${azuread_application.demo.object_id}"
  issuer         = var.openid_connect_url
  subject        = google_service_account.demo.unique_id
  description    = "Demo federated identity credential for secure integration"
  audiences      = [var.audience]
}

# Dynamic role assignment for the application based on required resource access
resource "azuread_app_role_assignment" "demo" {
  depends_on = [
    azuread_application.demo,
    data.azuread_service_principals.all,
    azuread_service_principal.demo,
    azurerm_role_assignment.demo,
  ]
  for_each = { for v in flatten([
    for rra in azuread_application.demo.required_resource_access : [
      for ra in rra.resource_access : {
        resource_object_id = one([
          for sp in data.azuread_service_principals.all.service_principals :
          sp.object_id if sp.client_id == rra.resource_app_id
        ])
        app_role_id = ra.id
      }
    ]
  ]) : join("|", [v.resource_object_id, v.app_role_id]) => v }

  principal_object_id = azuread_service_principal.demo.object_id
  resource_object_id  = each.value.resource_object_id
  app_role_id         = each.value.app_role_id
}
