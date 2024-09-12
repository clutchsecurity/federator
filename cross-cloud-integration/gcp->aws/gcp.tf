# Resource to create a Google Cloud service account
resource "google_service_account" "demo" {
  depends_on   = [random_string.random_suffix]
  account_id   = "${var.prefix}-demo-${random_string.random_suffix.result}" # Construct account ID using a prefix and a random suffix
  display_name = "demo Service Account"                                     # User-friendly name for the service account
}

# Assign the 'serviceAccountTokenCreator' role to the newly created service account
resource "google_project_iam_member" "service_account_token_creator" {
  depends_on = [google_service_account.demo]
  project    = var.gcp_project_name                                  # Specify the GCP project where the IAM role should be assigned
  role       = "roles/iam.serviceAccountTokenCreator"                # IAM role to assign
  member     = "serviceAccount:${google_service_account.demo.email}" # Construct the member identifier using the service account's email
}
