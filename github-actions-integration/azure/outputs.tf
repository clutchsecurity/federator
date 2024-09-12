# output "app_id" {
#     value = azuread_application_registration.my_app.application_id
# }

output "client_id" {
    value = azuread_application_registration.my_app.client_id
}

# output "object_id" {
#     value = azuread_application_registration.my_app.object_id
# }

# output "assigneeObjectId" {
#   value = azuread_service_principal.my_sp.id
# }

output "tenant_id" {
  value = data.azurerm_client_config.current.tenant_id
}

output "subscription_id" {
  value = data.azurerm_client_config.current.subscription_id
}
