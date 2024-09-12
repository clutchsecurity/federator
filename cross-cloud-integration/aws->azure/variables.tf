# Random string resource definition to ensure unique resource names and avoid conflicts.
resource "random_string" "random_suffix" {
  length  = 5       # Length of the random string
  special = false   # Excludes special characters for simplicity
  upper   = false   # Ensures all characters are lowercase to maintain uniformity
}

# Variable for specifying the AWS region where resources will be deployed.
variable "aws_cognito_region" {
  type    = string
  default = "us-east-1"
}

# Variable for specifying the specific AWS EC2 region, used particularly for EC2 resource deployments.
variable "aws_ec2_region" {
  type    = string
  default = "ap-south-1"
}

# Variable to define the AMI ID for deploying AWS EC2 instances.
variable "aws_ec2_ami_id" {
  description = "AMI ID for the EC2 instance"
  type        = string
  default     = "ami-0f58b397bc5c1f2e8"
}

# Variable to specify the default admin username for AWS EC2 instances.
variable "aws_admin_user" {
  description = "Default admin user for the EC2 instance"
  default     = "ubuntu"
  type        = string
}

# Variable for specifying the OpenID Connect issuer URL, important for identity federation with AWS.
variable "openid_connect_url" {
  type     = string
  default  = "https://cognito-identity.amazonaws.com"
  nullable = false  # Ensures that an issuer URL is always defined
}

# Variable to specify the developer provider name in identity pools, useful for federated identity setups.
variable "developer_provider_name" {
  type    = string
  default = "developerprovidername"
}

# Variable to specify the location for Azure resource groups, ensuring consistency across deployments.
variable "resource_group_location" {
  type     = string
  default  = "East US"  # Default location for resource groups
  nullable = false  # Ensures that a location is always specified for resource groups
}

# Variable to define a prefix for naming resources, aiding in their identification and management.
variable "prefix" {
  description = "Prefix used to name the resources for easy identification"
  type        = string
  default     = "aws-to-azure"
}
