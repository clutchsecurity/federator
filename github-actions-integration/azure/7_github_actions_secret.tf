resource "github_actions_secret" "azure_tenant_id" {
  depends_on      = [data.azurerm_client_config.current]
  repository      = var.github_repo_name
  secret_name     = "AZURE_TENANT_ID"
  plaintext_value = data.azurerm_client_config.current.tenant_id
}

resource "github_actions_secret" "azure_subscription_id" {
depends_on      = [data.azurerm_client_config.current]
  repository      = var.github_repo_name
  secret_name     = "AZURE_SUBSCRIPTION_ID"
  plaintext_value = data.azurerm_client_config.current.subscription_id
}

resource "github_actions_secret" "azure_client_id" {
depends_on = [azuread_application_registration.my_app]
  repository      = var.github_repo_name
  secret_name     = "AZURE_CLIENT_ID"
  plaintext_value = azuread_application_registration.my_app.client_id
}

# output "github_actions_secret_output" {
#   value = [
#     github_actions_secret.azure_client_id.plaintext_value,
#     github_actions_secret.azure_subscription_id.plaintext_value,
#     github_actions_secret.azure_tenant_id.plaintext_value
#     ]
#     sensitive = true
# }
