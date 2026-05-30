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
  default     = "aws-to-snowflake"
}

# Snowflake account identifier (e.g., "orgname-account_name" or "xy12345.us-east-1").
variable "snowflake_account" {
  description = "Snowflake account identifier"
  type        = string
}

# Name for the Snowflake service user that will be created with workload identity.
variable "snowflake_wif_username" {
  description = "Username for the Snowflake service user with workload identity"
  type        = string
  default     = "AWS_WIF_SERVICE_USER"
}

# Default role to assign to the Snowflake service user.
variable "snowflake_default_role" {
  description = "Default role for the Snowflake service user"
  type        = string
  default     = "PUBLIC"
}

# Snowflake warehouse for the service user to use.
variable "snowflake_warehouse" {
  description = "Snowflake warehouse for the service user"
  type        = string
  default     = ""
}
