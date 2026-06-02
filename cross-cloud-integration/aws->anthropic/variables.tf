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
  default     = "aws-to-anthropic"
}

# Anthropic Federation Rule ID.
# Created in the Claude Console under Settings > Workload Identity > Federation Rules.
variable "anthropic_federation_rule_id" {
  description = "Anthropic Federation Rule ID (created in Claude Console)"
  type        = string
}

# Anthropic Organization ID.
# Found in the Claude Console under Settings > Organization.
variable "anthropic_organization_id" {
  description = "Anthropic Organization ID (UUID format)"
  type        = string
}

# Anthropic Service Account ID.
# Created in the Claude Console under Settings > Service Accounts.
variable "anthropic_service_account_id" {
  description = "Anthropic Service Account ID (created in Claude Console)"
  type        = string
}

# Anthropic Workspace ID.
# The workspace the service account is a member of.
variable "anthropic_workspace_id" {
  description = "Anthropic Workspace ID"
  type        = string
}
