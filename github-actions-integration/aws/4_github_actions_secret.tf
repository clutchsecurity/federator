resource "github_actions_secret" "oidc_role_arn_secret" {
  depends_on      = [aws_iam_role.github_action]
  repository      = var.github_repo_name
  secret_name     = "OIDC_ROLE_ARN"
  plaintext_value = aws_iam_role.github_action.arn
}

