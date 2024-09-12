resource "azurerm_resource_group" "my_resource_group" {
  name     = "myResourceGroup"
  location = var.resource_group_location
}

data "azurerm_resource_group" "example" {
  depends_on = [ azurerm_resource_group.my_resource_group ]
  name = azurerm_resource_group.my_resource_group.name
}