resource "google_project_iam_member" "sa_viewer" {
    depends_on = [ google_service_account.sa ]
  project = "probable-anchor-420008"
  role    = "roles/iam.serviceAccountViewer"
  member  = "serviceAccount:${google_service_account.sa.email}"
}
