# Random string resource definition to ensure unique resource names and avoid conflicts.
resource "random_string" "random_suffix" {
  length  = 5     # Length of the random string
  special = false # Excludes special characters for simplicity
  upper   = false # Ensures all characters are lowercase to maintain uniformity
}

# Variable for specifying the AWS region where EC2 resources will be deployed.
variable "aws_ec2_region" {
  description = "AWS region for EC2 instance deployment"
  type        = string
  default     = "us-east-2"
}

# Variable to define the AMI ID for deploying AWS EC2 instances.
variable "aws_ec2_ami_id" {
  description = "AMI ID for the EC2 instance"
  type        = string
  default     = "ami-0257f1929a4806405"
}

# Variable to specify the default admin username for AWS EC2 instances.
variable "aws_admin_user" {
  description = "Default admin user for the EC2 instance"
  default     = "ubuntu"
  type        = string
}

# Variable to define a prefix for naming resources.
variable "prefix" {
  description = "Prefix used to name the resources for easy identification"
  type        = string
  default     = "aws-to-openai"
}

# OpenAI Workload Identity Provider ID.
# Created in the OpenAI dashboard under Settings > Security -> Workload Identity Provider.
variable "openai_identity_provider_id" {
  description = "OpenAI Workload Identity Provider ID (created in OpenAI dashboard)"
  type        = string
}

# OpenAI Service Account ID mapped to the Workload Identity Provider.
# Created in the OpenAI dashboard under Settings > Service Accounts.
variable "openai_service_account_id" {
  description = "OpenAI Service Account ID (created in OpenAI dashboard)"
  type        = string
}
