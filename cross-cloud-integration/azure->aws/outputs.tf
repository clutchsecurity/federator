# Generate the SSH command to log into the Azure VM.
output "ssh_login_command" {
  depends_on = [azurerm_linux_virtual_machine.demo]
  value      = "ssh ${var.azure_vm_admin_username}@${azurerm_linux_virtual_machine.demo.public_ip_address}"
  description = "SSH command to connect to the virtual machine."
}

# Output the password required for SSH login.
output "ssh_password" {
  value       = var.azure_vm_admin_password
  description = "Use this password to login to the VM."
}
