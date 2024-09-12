# Define variables with descriptions and default values

# Google Cloud project name
variable "gcp_project_name" {
  description = "GCP project name for Google resources"
  type        = string
}

# AWS region where the resources will be created
variable "aws_region" {
  description = "AWS region where resources will be created"
  type        = string
  default     = "ap-south-1"
}

# Prefix to be used for naming the resources to ensure uniqueness and easy identification
variable "prefix" {
  description = "Prefix used to name the resources for easy identification"
  type        = string
  default     = "aws-to-gcp"
}

# AMI ID to use for creating EC2 instances
variable "aws_ec2_ami_id" {
  description = "AMI ID for the EC2 instance"
  type        = string
  default     = "ami-0f58b397bc5c1f2e8"
}

# Default administrator username for accessing the EC2 instances
variable "aws_admin_user" {
  description = "Default admin user for the EC2 instance"
  default     = "ubuntu"
}

# Name of the SSH key to be used for the EC2 instances
variable "key_name" {
  description = "SSH key pair name"
  default     = "temporary-terraform-ec2.pem"
}

# Generate a random string to use as a suffix in resource names to ensure uniqueness
resource "random_string" "random_suffix" {
  length  = 5
  special = false
  upper   = false
}
