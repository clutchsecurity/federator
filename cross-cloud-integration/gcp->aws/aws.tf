# Resource to create an AWS IAM role for a demo application
# The role is configured to allow identity federation with Google Cloud's service account
resource "aws_iam_role" "demo_role" {
  depends_on = [
    random_string.random_suffix,
    google_service_account.demo,
  ]
  name = "${var.prefix}-demo-role-${random_string.random_suffix.result}" # Dynamic name based on provided prefix and a random suffix

  # Assume role policy that allows Google's federated accounts to assume this role
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = "accounts.google.com"
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "accounts.google.com:aud" = "${google_service_account.demo.unique_id}" # Only allow if the audience matches the Google service account's unique ID
        }
      }
    }]
  })
}

# Attach a predefined Amazon S3 ReadOnly policy to the previously defined AWS IAM role
resource "aws_iam_role_policy_attachment" "s3_readonly_policy" {
  depends_on = [aws_iam_role.demo_role]
  role       = aws_iam_role.demo_role.name                      # Reference to the IAM role
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess" # ARN for Amazon S3 ReadOnly Access policy
}
