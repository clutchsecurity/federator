resource "google_service_account" "sa" {
  account_id   = "my-service-account"
  display_name = "A service account that only Jane can use"
}
