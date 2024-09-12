resource "github_actions_secret" "workload_identity_provider" {
  depends_on      = [google_iam_workload_identity_pool_provider.example]
  repository      = var.github_repo_name
  secret_name     = "GCP_WORKLOAD_IDENTITY_PROVIDER"
  plaintext_value = google_iam_workload_identity_pool_provider.example.name
}

resource "github_actions_secret" "service_account_email" {
  depends_on      = [google_service_account.sa]
  repository      = var.github_repo_name
  secret_name     = "GCP_SERVICE_ACCOUNT_EMAIL"
  plaintext_value = google_service_account.sa.email
}
