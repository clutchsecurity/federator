# Output the SSH command to connect to the AWS EC2 instance
output "aws_ec2_ssh_login_command" {
  depends_on = [
    null_resource.copy_gcp_cred_file_to_aws_vm,
    aws_instance.demo
  ]
  value = "ssh -i ${var.key_name} ${var.aws_admin_user}@${aws_instance.demo.public_ip}"
}

# # Output the AWS region used for provisioning resources
# output "aws_ec2_region" {
#   value = var.aws_region
# }

# # Output the GCP credentials configuration file path
# output "gcp_cred_config_file" {
#   depends_on = [
#     null_resource.create_cred_config
#   ]
#   value = null_resource.create_cred_config.triggers["gcp_cred_config"]
# }
