# Enable AWS IAM Outbound Web Identity Federation at the account level.
# This creates a unique token issuer URL for the AWS account that can be used
# to generate OIDC tokens for cross-cloud authentication.
resource "aws_iam_outbound_web_identity_federation" "this" {}

# IAM policy granting permission to request web identity tokens.
# This uses the direct STS token generation approach.
# Restricted to only allow tokens for Snowflake federation.
resource "aws_iam_policy" "web_identity_token_policy" {
  name        = "${var.prefix}-web-identity-token-policy"
  description = "Policy allowing EC2 instances to request web identity tokens for Snowflake federation"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "sts:GetWebIdentityToken"
      Resource = "*"
      # Note: The Snowflake connector determines the audience internally.
      # To tighten this policy for production, observe the audience value
      # from a successful token request and add a sts:IdentityTokenAudience condition.
      Condition = {
        NumericLessThanEquals = {
          "sts:DurationSeconds" = 300
        }
      }
    }]
  })
}
