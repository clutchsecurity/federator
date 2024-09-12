resource "google_iam_workload_identity_pool_provider" "example" {
    depends_on = [ google_iam_workload_identity_pool.github_oidc ]
  workload_identity_pool_id          = google_iam_workload_identity_pool.github_oidc.workload_identity_pool_id
  workload_identity_pool_provider_id = "terraform-github"
  attribute_mapping = {
    "google.subject"  = "assertion.sub"
    "attribute.actor" = "assertion.actor"
    "attribute.aud"   = "assertion.aud"
    "attribute.org"   = "assertion.repository_owner"
    "attribute.repository" = "assertion.repository"
  }
  #   attribute_condition = "attribute.repository == \"testinguser883xxxefe\""
  oidc {
    issuer_uri = var.openid_connect_url
  }
}