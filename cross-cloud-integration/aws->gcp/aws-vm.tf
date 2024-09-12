# Create an IAM instance profile that EC2 instances can use to assume the specified IAM role
resource "aws_iam_instance_profile" "ec2_profile" {
  depends_on = [aws_iam_role.ec2_gcloud_cli_role]
  name       = "${var.prefix}-ec2_gcloud_cli_profile-${random_string.random_suffix.result}"
  role       = aws_iam_role.ec2_gcloud_cli_role.name
}

# Generate an RSA private key for SSH access to the EC2 instances
resource "tls_private_key" "demo_ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Register the generated public key with AWS to create an SSH key pair for EC2
resource "aws_key_pair" "key_pair" {
  depends_on = [tls_private_key.demo_ssh_key]
  key_name   = var.key_name
  public_key = tls_private_key.demo_ssh_key.public_key_openssh
}

# Save the private key locally with restricted permissions for secure access
resource "local_file" "private_key" {
  depends_on      = [tls_private_key.demo_ssh_key]
  content         = tls_private_key.demo_ssh_key.private_key_pem
  filename        = var.key_name
  file_permission = "400"
}

# Define a security group for the EC2 instance with specific ingress and egress rules
resource "aws_security_group" "sg_ec2" {
  name        = "${var.prefix}-sg_ec2"
  description = "Security group for EC2 instance"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow SSH access from any IP
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # Allow all outbound traffic
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create an EC2 instance with the specified configuration, including AMI, instance type, and security settings
resource "aws_instance" "demo" {
  depends_on = [
    aws_security_group.sg_ec2,
    aws_iam_instance_profile.ec2_profile,
    aws_key_pair.key_pair,
    google_service_account.wi_aws,
  ]
  ami                    = var.aws_ec2_ami_id
  instance_type          = "t2.micro"
  key_name               = aws_key_pair.key_pair.key_name
  vpc_security_group_ids = [aws_security_group.sg_ec2.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name
  user_data = templatefile("${path.module}/tpl/aws_ec2_user_data.tpl", {
    gcp_project_name          = var.gcp_project_name,
    admin_user                = var.aws_admin_user,
    gcp_service_account_email = google_service_account.wi_aws.email
  })
  metadata_options {
    # Allows the use of IMDSv1 because default generation of GCP create-cred-config doesn't include information that supports IMDS v2. To avoid, manually changing the generated cred-config, for demo purposes, we configure the AWS EC2 instance to support IMDS v1.
    http_tokens = "optional"
  }

  tags = {
    Name = "${var.prefix}-demo-instance"
  }

  root_block_device {
    volume_size = 10
    volume_type = "gp2"
  }

  provisioner "local-exec" {
    # Wait till machine is up and ready to accept ssh connections
    command = "until nc -z ${self.public_ip} 22; do echo 'Waiting for VM to become SSH-ready...'; sleep 10; done"
  }

  provisioner "remote-exec" {
    # Validate the ssh connection the created VM
    inline = [
      "echo 'VM is now reachable'"
    ]
    connection {
      type        = "ssh"
      host        = self.public_ip
      user        = var.aws_admin_user
      private_key = file("${local_file.private_key.filename}")
      agent       = false
    }
  }
}

# Use a null_resource to manage a script that copies the GCP credentials to the AWS VM
resource "null_resource" "copy_gcp_cred_file_to_aws_vm" {
  depends_on = [
    aws_instance.demo,
    null_resource.create_cred_config,
    random_string.random_suffix,
    local_file.private_key,
  ]
  triggers = {
    always_run      = timestamp()
    gcp_cred_config = "gcp-${random_string.random_suffix.result}.json"
  }

  # Provisioning command to securely copy the GCP credentials over to the AWS instance
  provisioner "local-exec" {
    when    = create
    command = "scp -i ${local_file.private_key.filename} -o StrictHostKeyChecking=no ${self.triggers["gcp_cred_config"]} ${var.aws_admin_user}@${aws_instance.demo.public_ip}:/home/${var.aws_admin_user}/gcp.json"
  }
}
