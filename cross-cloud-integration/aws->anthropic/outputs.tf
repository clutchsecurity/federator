# Output the SSH command to connect to the AWS EC2 instance
output "aws_ec2_ssh_login_command" {
  description = "SSH command to connect to the EC2 instance"
  depends_on = [
    aws_instance.demo,
    random_string.random_suffix
  ]
  value = "ssh -i ${random_string.random_suffix.result}.pem ${var.aws_admin_user}@${aws_instance.demo.public_ip}"
}

# Output the AWS issuer identifier for the account
output "aws_issuer_identifier" {
  description = "AWS account's unique issuer identifier for outbound federation"
  value       = aws_iam_outbound_web_identity_federation.this.issuer_identifier
}

# Output the IAM role ARN used for federation
output "aws_federation_role_arn" {
  description = "ARN of the IAM role used for Anthropic federation"
  value       = aws_iam_role.ec2_federation_role.arn
}

# Output the command to get a web identity token from the EC2 instance
output "get_token_command" {
  description = "Command to get AWS web identity token (run from EC2 instance)"
  value       = "aws sts get-web-identity-token --region ${var.aws_ec2_region} --audience https://api.anthropic.com --signing-algorithm RS256 --duration-seconds 900"
}
