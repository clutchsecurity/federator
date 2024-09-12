# Generate a private key for SSH access
resource "tls_private_key" "demo_ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

# Create a file to store the generated private SSH key
resource "local_file" "private_key_file" {
  content         = tls_private_key.demo_ssh_key.private_key_pem
  filename        = "${path.module}/demo_ssh_key.pem"
  file_permission = "0400"
}

# Create a virtual network within Azure
resource "azurerm_virtual_network" "demo" {
  name                = "${var.prefix}-vnet-${random_string.random_suffix.result}"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.demo.location
  resource_group_name = azurerm_resource_group.demo.name
}

# Define a subnet within the virtual network
resource "azurerm_subnet" "demo" {
  name                 = "${var.prefix}-subnet-${random_string.random_suffix.result}"
  resource_group_name  = azurerm_resource_group.demo.name
  virtual_network_name = azurerm_virtual_network.demo.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Allocate a public IP for Azure resources
resource "azurerm_public_ip" "demo" {
  name                = "${var.prefix}-public-ip-${random_string.random_suffix.result}"
  location            = azurerm_resource_group.demo.location
  resource_group_name = azurerm_resource_group.demo.name
  allocation_method   = "Dynamic"
}

# Configure a network interface for Azure VM
resource "azurerm_network_interface" "demo" {
  name                = "${var.prefix}-nic-${random_string.random_suffix.result}"
  location            = azurerm_resource_group.demo.location
  resource_group_name = azurerm_resource_group.demo.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.demo.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.demo.id
  }
}

# Deploy an Azure Linux virtual machine
resource "azurerm_linux_virtual_machine" "demo" {
  depends_on                      = [null_resource.create_cred_config]
  name                            = "${var.prefix}-vm-${random_string.random_suffix.result}"
  disable_password_authentication = true
  resource_group_name             = azurerm_resource_group.demo.name
  location                        = azurerm_resource_group.demo.location
  size                            = "Standard_B1ls" # Cheapest VM size for testing

  admin_username = var.admin_username

  admin_ssh_key {
    username   = var.admin_username
    public_key = tls_private_key.demo_ssh_key.public_key_openssh
  }

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

  custom_data = base64encode(templatefile("${path.module}/tpl/azure-vm-init-script.yaml.tpl", {
    admin_username   = var.admin_username
    gcp_project_name = var.gcp_project_name
  }))

  provisioner "local-exec" {
    command = "until nc -z ${self.public_ip_address} 22; do echo 'Waiting for VM to become SSH-ready...'; sleep 10; done"
  }

  provisioner "remote-exec" {
    inline = ["echo 'VM is now reachable'"]
    connection {
      type        = "ssh"
      host        = self.public_ip_address
      user        = var.admin_username
      private_key = file("${local_file.private_key_file.filename}")
      agent       = false
    }
  }
}

# Provision a script to copy the Google Cloud credentials file to the Azure VM
resource "null_resource" "copy_gcp_cred_file_to_azure_vm" {
  depends_on = [azurerm_linux_virtual_machine.demo]
  triggers = {
    always_run      = timestamp()
    gcp_cred_config = "gcp-${random_string.random_suffix.result}.json"
  }

  provisioner "local-exec" {
    when    = create
    command = <<EOT
      scp -o StrictHostKeyChecking=no -i ${local_file.private_key_file.filename} ${self.triggers["gcp_cred_config"]} ${azurerm_linux_virtual_machine.demo.admin_username}@${azurerm_linux_virtual_machine.demo.public_ip_address}:/home/${var.admin_username}/gcp.json
    EOT
  }

  provisioner "local-exec" {
    when    = destroy
    command = <<EOT
      rm -rf ${self.triggers["gcp_cred_config"]}
    EOT
  }
}
