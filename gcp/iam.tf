resource "google_service_account" "security_sa" {
  account_id   = "security-sa"
  display_name = "Security Service Account"
}

resource "google_project_iam_member" "security_sa_logging_viewer" {
  project = var.project_id
  role    = "roles/logging.viewer"
  member  = "serviceAccount:${google_service_account.security_sa.email}"
}
