resource "google_storage_bucket" "audit_logs_bucket" {
  name                        = "multicloud-gcl-logs-2026"
  location                    = "EU"
  uniform_bucket_level_access = true
  force_destroy               = true
}

resource "google_logging_project_sink" "audit_logs_sink" {
  name        = "audit-logs"
  destination = "storage.googleapis.com/${google_storage_bucket.audit_logs_bucket.name}"

  unique_writer_identity = true
}

resource "google_storage_bucket_iam_member" "log_writer" {
  bucket = google_storage_bucket.audit_logs_bucket.name
  role   = "roles/storage.objectCreator"
  member = google_logging_project_sink.audit_logs_sink.writer_identity
}
