# Create a Virtual Network in Azure for testing AWS connectivity.
resource "azurerm_virtual_network" "demo" {
  depends_on = [ random_string.random_suffix, azurerm_resource_group.demo ]
  name                = "${var.prefix}-vnet-${random_string.random_suffix.result}"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.demo.location
  resource_group_name = azurerm_resource_group.demo.name
}

# Create a subnet within the virtual network.
resource "azurerm_subnet" "demo" {
  depends_on = [azurerm_virtual_network.demo, random_string.random_suffix]
  name                 = "${var.prefix}-subnet-${random_string.random_suffix.result}"
  resource_group_name  = azurerm_resource_group.demo.name
  virtual_network_name = azurerm_virtual_network.demo.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Define a public IP resource for network accessibility.
resource "azurerm_public_ip" "demo" {
  depends_on = [ azurerm_resource_group.demo, random_string.random_suffix ]
  name                = "${var.prefix}-public-ip-${random_string.random_suffix.result}"
  location            = azurerm_resource_group.demo.location
  resource_group_name = azurerm_resource_group.demo.name
  allocation_method   = "Dynamic"
}

# Configure a network interface with the public IP and subnet.
resource "azurerm_network_interface" "demo" {
  depends_on = [
    azurerm_subnet.demo,
    azurerm_resource_group.demo,
    random_string.random_suffix,
    azurerm_public_ip.demo,
  ]
  name                = "${var.prefix}-network-interface-${random_string.random_suffix.result}"
  location            = azurerm_resource_group.demo.location
  resource_group_name = azurerm_resource_group.demo.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.demo.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.demo.id
  }
}

# Set up a Linux virtual machine that connects to the defined network interface.
resource "azurerm_linux_virtual_machine" "demo" {
  depends_on = [
    azurerm_network_interface.demo,
    aws_iam_role.assume_role,
    aws_iam_openid_connect_provider.default,
    random_string.random_suffix,
    azurerm_resource_group.demo,
    azurerm_user_assigned_identity.demo,
    data.aws_caller_identity.current,
    azuread_application.demo,
  ]
  name                        = "${var.prefix}-vm-${random_string.random_suffix.result}"
  disable_password_authentication = false
  resource_group_name         = azurerm_resource_group.demo.name
  location                    = azurerm_resource_group.demo.location
  size                        = "Standard_B1ls"  # Entry-level VM size

  admin_username              = var.azure_vm_admin_username
  admin_password              = var.azure_vm_admin_password

  network_interface_ids = [azurerm_network_interface.demo.id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.demo.id]
  }

  custom_data = base64encode(
    templatefile("${path.module}/tpl/azure-vm-init-script.yaml.tpl", {
      account_id = data.aws_caller_identity.current.account_id
      aws_iam_role_name = aws_iam_role.assume_role.name
      audience = tolist(azuread_application.demo.identifier_uris)[0]
      app_role = var.app_role
    })
  )
}
