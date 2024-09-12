resource "azuread_service_principal" "my_sp" {
    depends_on = [ azuread_application_registration.my_app ]
client_id = azuread_application_registration.my_app.client_id
}
