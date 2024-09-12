locals {
  // Load and format the trust policy from the template file
  trust_policy = templatefile("${path.module}/tpl/trust-policy-for-github-OIDC.json.tpl", {
    oidc_arn  = aws_iam_openid_connect_provider.default.arn
    domain    = data.idpfingerprint.default.domain
    github_username = var.github_username
    audience  = jsonencode(var.client_id_list)
  })
}

resource "aws_iam_role" "github_action" {
  depends_on = [ aws_iam_openid_connect_provider.default ]
  name                 = "GitHubAction-AssumeRoleWithAction-Terraform"
  assume_role_policy   = local.trust_policy
}

