# Data source to get the AWS caller identity to access account-specific details like account ID
data "aws_caller_identity" "current" {}

# Create an IAM role for EC2 that can be assumed by AWS services
resource "aws_iam_role" "ec2_gcloud_cli_role" {
  depends_on = [random_string.random_suffix]
  name       = "${var.prefix}-ec2_gcloud_cli_role-${random_string.random_suffix.result}"

  # IAM policy that allows an EC2 instance to assume this role
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Action    = "sts:AssumeRole"
        Principal = { Service = "ec2.amazonaws.com" }
      }
    ]
  })
}
