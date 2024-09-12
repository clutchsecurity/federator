resource "azurerm_role_assignment" "example" {
    depends_on = [ azurerm_resource_group.my_resource_group, azuread_service_principal.my_sp ]
  scope                = data.azurerm_resource_group.example.id
  role_definition_name = "Contributor"
  principal_id         = azuread_service_principal.my_sp.id
}
