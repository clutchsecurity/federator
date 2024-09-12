locals {
  // Load and format the trust policy from the template file
  github_action_content = templatefile("${path.module}/tpl/gcp-github-actions-workflow.yml.tpl", {
    workload_identity_provider_secret_name = github_actions_secret.workload_identity_provider.secret_name
    service_account_email_secret_name = github_actions_secret.service_account_email.secret_name
  })
}

resource "random_string" "github_actions_workflow_filename" {
  length = 8
  special = false
}

resource "github_repository_file" "foo" {
  depends_on = [ random_string.github_actions_workflow_filename, local.github_action_content, github_actions_secret.workload_identity_provider, github_actions_secret.service_account_email, google_project_iam_member.sa_viewer, google_service_account_iam_binding.admin-account-iam ]
  repository          = var.github_repo_name
  branch              = "main"
  file                = ".github/workflows/gcp-${random_string.github_actions_workflow_filename.result}.yml"
  content             = local.github_action_content
  commit_message      = "Committed GCP with love from Terraform"
}

output "github_repository_details" {
    value = [
        github_repository_file.foo.file,
        github_repository_file.foo.repository
    ]
    description = "Github repository details"
}