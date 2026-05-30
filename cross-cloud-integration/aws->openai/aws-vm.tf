# VPC for the demo EC2 instance
resource "aws_vpc" "demo" {
  provider             = aws.ec2-region
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.prefix}-vpc"
  }
}

# Internet Gateway for public internet access
resource "aws_internet_gateway" "demo" {
  provider = aws.ec2-region
  vpc_id   = aws_vpc.demo.id

  tags = {
    Name = "${var.prefix}-igw"
  }
}

# Public subnet for the EC2 instance
resource "aws_subnet" "demo" {
  provider                = aws.ec2-region
  vpc_id                  = aws_vpc.demo.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.prefix}-subnet"
  }
}

# Route table for the public subnet
resource "aws_route_table" "demo" {
  provider = aws.ec2-region
  vpc_id   = aws_vpc.demo.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.demo.id
  }

  tags = {
    Name = "${var.prefix}-rt"
  }
}

# Associate route table with subnet
resource "aws_route_table_association" "demo" {
  provider       = aws.ec2-region
  subnet_id      = aws_subnet.demo.id
  route_table_id = aws_route_table.demo.id
}

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
  vpc_id      = aws_vpc.demo.id

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

  tags = {
    Name = "${var.prefix}-sg"
  }
}

# AWS IAM Role for EC2 instances, allowing them to request web identity tokens for OpenAI federation.
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
    aws_key_pair.key_pair,
    aws_iam_instance_profile.ec2_federation_profile,
    aws_iam_outbound_web_identity_federation.this,
  ]
  provider               = aws.ec2-region
  ami                    = var.aws_ec2_ami_id
  instance_type          = "t4g.micro"
  key_name               = aws_key_pair.key_pair.key_name
  subnet_id              = aws_subnet.demo.id
  vpc_security_group_ids = [aws_security_group.sg_ec2.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_federation_profile.id
  user_data = templatefile("${path.module}/tpl/aws-vm.tpl", {
    aws_region                  = var.aws_ec2_region,
    openai_identity_provider_id = var.openai_identity_provider_id,
    openai_service_account_id   = var.openai_service_account_id,
  })
  tags = {
    Name = "${var.prefix}-demo-instance"
  }
}
