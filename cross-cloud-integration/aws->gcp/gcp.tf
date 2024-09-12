# Data source to fetch current Google Cloud project details
data "google_project" "project" {}

# Create a Workload Identity Pool in GCP for managing identities from AWS
resource "google_iam_workload_identity_pool" "avi_aws_pool" {
  depends_on = [ random_string.random_suffix ]
  workload_identity_pool_id = "${var.prefix}-aws-pool-id-${random_string.random_suffix.result}"
  display_name              = "aws-pool-id-${random_string.random_suffix.result}"
  description               = "Identity pool for AWS to access GCP resources"
}

# Provider in the workload identity pool for AWS
resource "google_iam_workload_identity_pool_provider" "avi_aws_provider" {
  depends_on = [ 
    random_string.random_suffix,
    google_iam_workload_identity_pool.avi_aws_pool,
    data.aws_caller_identity.current,
    aws_iam_role.ec2_gcloud_cli_role,
  ]
  workload_identity_pool_id          = google_iam_workload_identity_pool.avi_aws_pool.workload_identity_pool_id
  workload_identity_pool_provider_id = "aws-pool-provider-id-${random_string.random_suffix.result}"
  display_name                       = "aws-pool-provider-id-${random_string.random_suffix.result}"
  attribute_condition                = "attribute.aws_role==\"arn:aws:sts::${data.aws_caller_identity.current.account_id}:assumed-role/${aws_iam_role.ec2_gcloud_cli_role.name}\""

  # Configuration to link AWS account to this provider
  aws {
    account_id = data.aws_caller_identity.current.account_id
  }
}

# Create a Google service account to be used with the Workload Identity Pool
resource "google_service_account" "wi_aws" {
  depends_on = [ random_string.random_suffix ]
  account_id   = "${var.prefix}-wi-aws-${random_string.random_suffix.result}"
  display_name = "Workload Identity AWS-${random_string.random_suffix.result}"
}

# Bind the Google service account to the Workload Identity Pool with necessary roles
resource "google_service_account_iam_member" "wi_aws_binding" {
  depends_on = [ 
    google_service_account.wi_aws,
    data.google_project.project,
    google_iam_workload_identity_pool.avi_aws_pool,
  ]
  service_account_id = google_service_account.wi_aws.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/projects/${data.google_project.project.number}/locations/global/workloadIdentityPools/${google_iam_workload_identity_pool.avi_aws_pool.workload_identity_pool_id}/*"
}

# Define the roles to be assigned to the Google service account
locals {
  roles = {
    "viewer"                      = "roles/viewer",
    # "serviceAccountTokenCreator"  = "roles/iam.serviceAccountTokenCreator",
    # "serviceAccountUser"          = "roles/iam.serviceAccountUser"
  }
}

# Dynamically assign roles to the Google service account
resource "google_project_iam_member" "wi_aws_binding" {
  for_each   = local.roles

  depends_on = [google_service_account.wi_aws]
  project    = var.gcp_project_name
  role       = each.value
  member     = "serviceAccount:${google_service_account.wi_aws.email}"
}

# A null_resource to handle the creation and deletion of GCP credentials configuration file
# For this demo, this credentials file will be copied to aws ec2 instance
# and ec2 will connect to Google Cloud using this file.
resource "null_resource" "create_cred_config" {
  depends_on = [
    google_service_account.wi_aws,
    google_iam_workload_identity_pool.avi_aws_pool,
    google_iam_workload_identity_pool_provider.avi_aws_provider,
    random_string.random_suffix,
    data.google_project.project,
  ]

  triggers = {
    always_run     = timestamp()
    gcp_cred_config = "gcp-${random_string.random_suffix.result}.json"
  }

  # Local-exec provisioner to create the GCP credentials configuration file using gcloud CLI
  provisioner "local-exec" {
    when    = create
    command = <<EOT
    set -x
    gcloud iam workload-identity-pools create-cred-config projects/${data.google_project.project.number}/locations/global/workloadIdentityPools/${google_iam_workload_identity_pool.avi_aws_pool.workload_identity_pool_id}/providers/${google_iam_workload_identity_pool_provider.avi_aws_provider.workload_identity_pool_provider_id} \
      --service-account=${google_service_account.wi_aws.email} \
      --aws \
      --output-file=${self.triggers["gcp_cred_config"]}
    test -f ${self.triggers["gcp_cred_config"]} && echo "Success" || echo "Failure"
EOT
  }

  # Local-exec provisioner to remove the credentials file on resource destruction
  provisioner "local-exec" {
    when    = destroy
    command = "rm -rf ${self.triggers["gcp_cred_config"]}"
  }
}
