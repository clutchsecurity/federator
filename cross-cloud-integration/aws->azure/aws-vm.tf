# TLS private key resource for generating an RSA private key used for SSH access to EC2 instances.
resource "tls_private_key" "demo_ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# AWS Key Pair resource to manage the SSH key pair used for EC2 instances.
resource "aws_key_pair" "key_pair" {
  provider   = aws.ec2-region
  key_name   = random_string.random_suffix.result
  public_key = tls_private_key.demo_ssh_key.public_key_openssh
}

# Local file resource to save the generated private SSH key securely.
resource "local_file" "private_key" {
  content         = tls_private_key.demo_ssh_key.private_key_pem
  filename        = "${path.module}/${random_string.random_suffix.result}.pem"
  file_permission = "400"
}

# AWS Security Group resource to define the security rules for EC2 instances.
resource "aws_security_group" "sg_ec2" {
  provider    = aws.ec2-region
  name        = "${var.prefix}-sg_ec2"
  description = "Security group for EC2 instance"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# AWS IAM Role for EC2 instances, allowing them to request web identity tokens for Azure federation.
resource "aws_iam_role" "ec2_federation_role" {
  name = "${var.prefix}-ec2-federation-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

# Attaches the web identity token policy to the IAM role.
resource "aws_iam_role_policy_attachment" "web_identity_policy_attachment" {
  depends_on = [aws_iam_role.ec2_federation_role, aws_iam_policy.web_identity_token_policy]
  role       = aws_iam_role.ec2_federation_role.name
  policy_arn = aws_iam_policy.web_identity_token_policy.arn
}

# Instance profile for EC2 that allows the use of the IAM role within EC2.
resource "aws_iam_instance_profile" "ec2_federation_profile" {
  depends_on = [aws_iam_role.ec2_federation_role]
  name       = "${var.prefix}-ec2-federation-profile"
  role       = aws_iam_role.ec2_federation_role.name
}

# AWS EC2 instance resource configured to use the defined resources.
resource "aws_instance" "demo" {
  depends_on = [
    azuread_application.demo,
    aws_key_pair.key_pair,
    aws_iam_instance_profile.ec2_federation_profile,
    aws_iam_outbound_web_identity_federation.this,
    data.azurerm_client_config.current,
  ]
  provider               = aws.ec2-region
  ami                    = var.aws_ec2_ami_id
  instance_type          = "t2.nano"
  key_name               = aws_key_pair.key_pair.key_name
  vpc_security_group_ids = [aws_security_group.sg_ec2.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_federation_profile.id
  user_data = templatefile("${path.module}/tpl/aws-vm.tpl", {
    azuread_application_demo_client_id = azuread_application.demo.client_id,
    azure_tenant_id                    = data.azurerm_client_config.current.tenant_id,
  })
  tags = {
    Name = "${var.prefix}-demo-instance"
  }
}
