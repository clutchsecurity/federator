# Output the SSH command required to connect to the deployed Azure Linux VM
output "ssh_command" {
  # Ensure this output waits for the virtual machine and related resources to be created
  depends_on = [
    azurerm_linux_virtual_machine.demo,
    null_resource.copy_gcp_cred_file_to_azure_vm,
    null_resource.create_cred_config
  ]

  # Formulate the SSH command using dynamic values from the deployment
  value = "ssh -i ${local_file.private_key_file.filename} ${azurerm_linux_virtual_machine.demo.admin_username}@${azurerm_linux_virtual_machine.demo.public_ip_address}"
}
