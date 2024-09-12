resource "google_service_account_iam_binding" "admin-account-iam" {
    depends_on = [google_service_account.sa, google_iam_workload_identity_pool.github_oidc]
  service_account_id = google_service_account.sa.name
  role               = "roles/iam.workloadIdentityUser"
  members = [
    "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github_oidc.name}/attribute.repository/${var.github_username}/${var.github_repo_name}"
  ]
}