# This identity pool configures identity providers and federations in AWS environments.
resource "aws_cognito_identity_pool" "my_identity_pool" {
  identity_pool_name               = "${var.prefix}-terraform"
  allow_unauthenticated_identities = false
  developer_provider_name = var.developer_provider_name
}

# Resource definition for an IAM policy specifically for the Cognito Identity Pool.
# This policy grants permissions for specific Cognito actions.
resource "aws_iam_policy" "cognito_policy" {
  depends_on = [ aws_cognito_identity_pool.my_identity_pool ]
  name        = "${var.prefix}-cognito-policy"
  description = "Policy for Cognito actions on specific APIs"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "cognito-identity:GetOpenIdTokenForDeveloperIdentity"
      ]
      Resource = aws_cognito_identity_pool.my_identity_pool.arn
    }]
  })
}

# External data source to invoke an AWS CLI command via a bash script.
# This command retrieves an OpenID Connect token for a specific developer identity.
data "external" "aws_get_cognito_identity_local_execution" {
  depends_on = [ aws_cognito_identity_pool.my_identity_pool ]
  program = ["bash", "-c", "aws cognito-identity get-open-id-token-for-developer-identity --identity-pool-id ${aws_cognito_identity_pool.my_identity_pool.id} --logins ${var.developer_provider_name}=developer_provider_value --region ${var.aws_cognito_region}"]
}
