locals {
  secret_names = [
    "CALENDAR_ID",
    "SERVICE_ACCOUNT_KEY"
  ]
}

resource "google_secret_manager_secret" "service_account_key" {
  secret_id = "SERVICE_ACCOUNT_KEY"
  project   = var.project_id

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "service_account_key_version" {
  secret      = google_secret_manager_secret.service_account_key.id
  secret_data = base64decode(google_service_account_key.service_sa_key.private_key)
}

resource "google_secret_manager_secret" "calendar_id" {
  secret_id = "CALENDAR_ID"
  project   = var.project_id

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "calendar_id_version" {
  secret      = google_secret_manager_secret.calendar_id.id
  secret_data = var.calendar_id
}
