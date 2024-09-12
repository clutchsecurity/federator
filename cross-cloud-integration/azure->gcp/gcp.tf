# Data source to retrieve the current GCP project details
data "google_project" "project" {
}

# Create a Workload Identity Pool in Google IAM for Azure workload federation
resource "google_iam_workload_identity_pool" "avi_azure_pool" {
  workload_identity_pool_id = "${var.prefix}-pool-id-${random_string.random_suffix.result}"
  display_name              = "${var.prefix}-pool-display-${random_string.random_suffix.result}"
  description               = "azure workload federation"
}

# Create a provider within the Workload Identity Pool for Azure
resource "google_iam_workload_identity_pool_provider" "avi_azure_provider" {
  depends_on                         = [google_iam_workload_identity_pool.avi_azure_pool]
  workload_identity_pool_id          = google_iam_workload_identity_pool.avi_azure_pool.workload_identity_pool_id
  workload_identity_pool_provider_id = "${var.prefix}-provider-id-${random_string.random_suffix.result}"
  display_name                       = "${var.prefix}-provider-${random_string.random_suffix.result}"

  oidc {
    issuer_uri        = "https://sts.windows.net/${data.azuread_client_config.current.tenant_id}/"
    allowed_audiences = tolist(azuread_application.demo.identifier_uris)
  }

  attribute_mapping = {
    "google.subject" = "assertion.sub"
  }
}

# Define a Google service account for Workload Identity
resource "google_service_account" "wi_azure" {
  account_id   = "${var.prefix}-wi-gcp-${random_string.random_suffix.result}"
  display_name = "${var.prefix}-Workload Identity GCP-${random_string.random_suffix.result}"
}

# Bind roles to the service account based on Workload Identity
resource "google_service_account_iam_member" "wi_azure_binding" {
  depends_on         = [google_service_account.wi_azure, google_iam_workload_identity_pool.avi_azure_pool]
  service_account_id = google_service_account.wi_azure.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/projects/${data.google_project.project.number}/locations/global/workloadIdentityPools/${google_iam_workload_identity_pool.avi_azure_pool.workload_identity_pool_id}/*"

  condition {
    title       = "Bind specific identity"
    description = "Only apply this to identities with a specific assertion.sub claim i.e service account unique identifier"
    expression  = "true"
  }
}

# Set roles for the Google service account
locals {
  roles = {
    "viewer" = "roles/viewer",
  }
}

# Dynamically assign predefined roles to the Google service account
resource "google_project_iam_member" "wi_azure_binding" {
  for_each   = local.roles
  depends_on = [google_service_account.wi_azure]
  project    = var.gcp_project_name
  role       = each.value
  member     = "serviceAccount:${google_service_account.wi_azure.email}"
}

# Provision credentials for integration between Google Cloud and Azure
# For this demo, this credentials file will be copied to azure vm instance
# and vm will connect to Google Cloud using this file.
resource "null_resource" "create_cred_config" {
  depends_on = [
    google_service_account.wi_azure,
    google_iam_workload_identity_pool.avi_azure_pool,
    google_iam_workload_identity_pool_provider.avi_azure_provider,
    azuread_application.demo,
    random_string.random_suffix
  ]
  triggers = {
    always_run      = timestamp()
    gcp_cred_config = "gcp-${random_string.random_suffix.result}.json"
  }

  provisioner "local-exec" {
    when    = create
    command = <<EOT
      set -x
      gcloud iam workload-identity-pools create-cred-config projects/${data.google_project.project.number}/locations/global/workloadIdentityPools/${google_iam_workload_identity_pool.avi_azure_pool.workload_identity_pool_id}/providers/${google_iam_workload_identity_pool_provider.avi_azure_provider.workload_identity_pool_provider_id} \
      --service-account=${google_service_account.wi_azure.email} \
      --azure \
      --app-id-uri ${tolist(azuread_application.demo.identifier_uris)[0]} \
      --output-file=gcp-${random_string.random_suffix.result}.json
      test -f gcp-${random_string.random_suffix.result}.json && echo "Success" || echo "Failure"
    EOT
  }

  provisioner "local-exec" {
    when    = destroy
    command = <<EOT
      rm -rf ${self.triggers["gcp_cred_config"]}
    EOT
  }
}
