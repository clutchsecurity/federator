# Output the SSH command to connect to the AWS EC2 instance
output "aws_ec2_ssh_login_command" {
  depends_on = [
    aws_instance.demo,
    random_string.random_suffix
  ]
  value = "ssh -i ${random_string.random_suffix.result}.pem ${var.aws_admin_user}@${aws_instance.demo.public_ip}"
}
