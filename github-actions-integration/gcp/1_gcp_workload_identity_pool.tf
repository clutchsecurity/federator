resource "random_string" "workload_identity_pool" {
  length           = 8
  special = false
  upper = false
}

resource "google_iam_workload_identity_pool" "github_oidc" {
    depends_on = [ random_string.workload_identity_pool ]
  workload_identity_pool_id = "terraform-example-pool-${random_string.workload_identity_pool.result}"
    # display_name              = "Terraform GitHub OIDC"
  disabled                  = false
}
