resource "azuread_application_federated_identity_credential" "example" {
    depends_on = [ azuread_application_registration.my_app, azurerm_role_assignment.example ]
  display_name = "hwatever"
  application_id = "/applications/${azuread_application_registration.my_app.object_id}"
#   name                  = var.credential_name
  issuer                = var.openid_connect_url
  subject               = "repo:${var.github_username}/${var.github_repo_name}:ref:refs/heads/${var.github_repo_branch}"
  description           = "Testing"
  audiences             = ["api://AzureADTokenExchange"]
}
