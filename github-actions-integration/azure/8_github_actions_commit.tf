locals {
  // Load and format the trust policy from the template file
  github_action_content = templatefile("${path.module}/tpl/azure-github-actions-workflow.yml.tpl", {
    client_id_secret_name = github_actions_secret.azure_client_id.secret_name
    tenant_id_secret_name = github_actions_secret.azure_tenant_id.secret_name
    subscription_id_secret_name = github_actions_secret.azure_subscription_id.secret_name
  })
}

resource "random_string" "github_actions_workflow_filename" {
  length           = 8
  special = false
}

resource "github_repository_file" "foo" {
  depends_on = [ github_actions_secret.azure_subscription_id, github_actions_secret.azure_tenant_id, github_actions_secret.azure_client_id, azuread_application_federated_identity_credential.example ]
  repository          = var.github_repo_name
  branch              = "main"
  file                = ".github/workflows/azure-${random_string.github_actions_workflow_filename.result}.yml"
  content             = local.github_action_content
  commit_message      = "Committed azure with love from Terraform"
}

output "github_repository_details" {
    value = [
        github_repository_file.foo.file,
        github_repository_file.foo.repository
    ]
    description = "Github repository details"
}