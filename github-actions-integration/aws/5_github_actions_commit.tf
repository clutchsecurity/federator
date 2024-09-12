locals {
  // Load and format the trust policy from the template file
  github_action_content = templatefile("${path.module}/tpl/github-actions-workflow.yml.tpl", {
    oidc_role_arn_secret_name = github_actions_secret.oidc_role_arn_secret.secret_name
    role_session_name = var.role_session_name
    aws_region = var.aws_region
  })
}

resource "random_string" "github_actions_workflow_filename" {
  length = 8
  special = false
  upper = false
}

resource "github_repository_file" "github_actions_workflow" {
  depends_on = [ github_actions_secret.oidc_role_arn_secret ]
  repository          = var.github_repo_name
  branch              = "main"
  file                = format(".github/workflows/aws-%s.yml", random_string.github_actions_workflow_filename.result)
  content             = local.github_action_content
  commit_message      = "Committed AWS with love from Terraform"
}

