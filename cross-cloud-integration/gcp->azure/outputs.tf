# Output the SSH login command for the Google Compute Instance
output "gcp_ssh_login_command" {
  depends_on = [
    google_compute_instance.demo_instance,
    local_file.private_key_file,
  ]
  value = "gcloud compute ssh --zone ${google_compute_instance.demo_instance.zone} --project ${var.gcp_project_name} --ssh-key-file ${local_file.private_key_file.filename} ${var.gcp_vm_admin_user}@${google_compute_instance.demo_instance.name}"
  # This command utilizes gcloud to establish an SSH connection using the generated private key file.
  # It specifies the admin user, project, and zone to ensure the command can be executed without requiring additional inputs.
}

# Output the command to be manually run after SSHing into the instance
output "manual_operation" {
  depends_on = [
    google_compute_instance.demo_instance,
    local_file.private_key_file,
  ]
  value = "Post SSH run, 'bash /etc/profile.d/set_env_vars.sh'"
  # This output suggests a manual operation to execute the script that configures AWS credentials via the environment.
  # The script sets up AWS environment variables based on a federated identity, enabling AWS CLI operations.
}
