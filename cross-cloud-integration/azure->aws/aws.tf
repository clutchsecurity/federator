# Retrieve AWS caller identity details.
data "aws_caller_identity" "current" {}

# Fetch TLS certificate for Azure OIDC configuration.
data "tls_certificate" "azure" {
  url = "https://sts.windows.net/${data.azuread_client_config.current.tenant_id}/.well-known/openid-configuration"
}

# Create an AWS IAM OpenID Connect provider for Azure.
resource "aws_iam_openid_connect_provider" "default" {
  url             = "https://sts.windows.net/${data.azuread_client_config.current.tenant_id}/"
  client_id_list  = tolist(azuread_application.demo.identifier_uris)
  thumbprint_list = [data.tls_certificate.azure.certificates[0].sha1_fingerprint]
}

# Define a local trust policy from a template.
locals {
  trust_policy = templatefile("${path.module}/tpl/azure-trust-policy.json.tpl", {
    aws_account_id  = data.aws_caller_identity.current.account_id
    azure_tenant_id = data.azuread_client_config.current.tenant_id
    identifier_uri  = tolist(azuread_application.demo.identifier_uris)[0]
    principal_id    = azurerm_user_assigned_identity.demo.principal_id
  })
}

# Create an IAM role with an OIDC-based trust policy.
resource "aws_iam_role" "assume_role" {
  depends_on         = [aws_iam_openid_connect_provider.default]
  name               = "${var.prefix}-AssumeRole-${random_string.random_suffix.result}"
  assume_role_policy = local.trust_policy
}

# Attach an S3 read-only access policy to the IAM role.
resource "aws_iam_role_policy_attachment" "s3_readonly_policy" {
  depends_on = [aws_iam_role.assume_role]
  role       = aws_iam_role.assume_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}
