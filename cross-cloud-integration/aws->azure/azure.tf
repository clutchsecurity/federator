# Data source to fetch current Azure client configuration
data "azurerm_client_config" "current" {}

# Data resource to fetch published app IDs for known applications (like Microsoft Graph)
data "azuread_application_published_app_ids" "well_known" {}

# Service principal data source for Microsoft Graph
data "azuread_service_principal" "msgraph" {
  depends_on = [data.azuread_application_published_app_ids.well_known]
  client_id  = data.azuread_application_published_app_ids.well_known.result.MicrosoftGraph
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
  display_name     = "${var.prefix} Demo ${random_string.random_suffix.result}"
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
  depends_on = [azuread_application.demo]
  client_id  = azuread_application.demo.client_id
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

# Federated identity credential associated with the Azure AD application.
# This uses AWS IAM Outbound Web Identity Federation instead of Cognito.
# The issuer is the AWS account's token issuer URL and the subject is the IAM role ARN.
resource "azuread_application_federated_identity_credential" "demo" {
  depends_on = [
    azuread_application.demo,
    azurerm_role_assignment.demo,
    azuread_app_role_assignment.demo,
    random_string.random_suffix,
    aws_iam_outbound_web_identity_federation.this,
    aws_iam_role.ec2_federation_role,
  ]
  display_name   = "${var.prefix}-demo-${random_string.random_suffix.result}"
  application_id = "/applications/${azuread_application.demo.object_id}"
  # Use the AWS account's unique issuer identifier from the outbound federation resource
  issuer = aws_iam_outbound_web_identity_federation.this.issuer_identifier
  # The subject is the ARN of the IAM role that will request tokens
  subject     = aws_iam_role.ec2_federation_role.arn
  description = "Federated identity credential for AWS to Azure integration using AWS Outbound Identity Federation"
  # Azure's standard audience for token exchange
  audiences = ["api://AzureADTokenExchange"]
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
