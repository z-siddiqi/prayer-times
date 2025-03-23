provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_project_service" "required_apis" {
  for_each = toset([
    "run.googleapis.com",
    "artifactregistry.googleapis.com",
    "cloudbuild.googleapis.com",
    "secretmanager.googleapis.com",
    "cloudscheduler.googleapis.com"
  ])

  project            = var.project_id
  service            = each.key
  disable_on_destroy = false
}

data "google_artifact_registry_repository" "repository" {
  location      = var.region
  repository_id = "${var.project_id}-${var.service_name}"
  project       = var.project_id
}

resource "google_cloud_run_v2_service" "service" {
  name     = var.service_name
  location = var.region
  ingress  = "INGRESS_TRAFFIC_ALL"

  template {
    service_account = google_service_account.service_sa.email

    containers {
      image = "${var.region}-docker.pkg.dev/${var.project_id}/${data.google_artifact_registry_repository.repository.repository_id}/${var.service_name}:latest"

      dynamic "env" {
        for_each = local.secret_names
        content {
          name = env.value
          value_source {
            secret_key_ref {
              secret  = env.value
              version = "latest"
            }
          }
        }
      }

      resources {
        limits = {
          cpu    = "1000m"
          memory = "512Mi"
        }
        cpu_idle = true
      }
    }

    scaling {
      min_instance_count = 0
      max_instance_count = 1
    }
  }
}

resource "google_cloudbuild_trigger" "deploy" {
  name            = "${var.service_name}-deploy"
  description     = "Build and deploy ${var.service_name}"
  location        = var.region
  service_account = google_service_account.cloudbuild_sa.id

  github {
    owner = "z-siddiqi"
    name  = var.github_repo_name
    push {
      branch = "^main$"
    }
  }

  build {
    options {
      logging = "CLOUD_LOGGING_ONLY"
    }

    step {
      name = "gcr.io/cloud-builders/docker"
      args = [
        "build",
        "-t", "${var.region}-docker.pkg.dev/${var.project_id}/${data.google_artifact_registry_repository.repository.repository_id}/${var.service_name}:$COMMIT_SHA",
        "-t", "${var.region}-docker.pkg.dev/${var.project_id}/${data.google_artifact_registry_repository.repository.repository_id}/${var.service_name}:latest",
        "."
      ]
    }

    step {
      name = "gcr.io/cloud-builders/docker"
      args = ["push", "--all-tags", "${var.region}-docker.pkg.dev/${var.project_id}/${data.google_artifact_registry_repository.repository.repository_id}/${var.service_name}"]
    }

    step {
      name       = "gcr.io/google.com/cloudsdktool/cloud-sdk"
      entrypoint = "gcloud"
      args = [
        "run",
        "deploy",
        var.service_name,
        "--image",
        "${var.region}-docker.pkg.dev/${var.project_id}/${data.google_artifact_registry_repository.repository.repository_id}/${var.service_name}:$COMMIT_SHA",
        "--region",
        var.region,
        "--platform",
        "managed"
      ]
    }

    images = [
      "${var.region}-docker.pkg.dev/${var.project_id}/${data.google_artifact_registry_repository.repository.repository_id}/${var.service_name}:$COMMIT_SHA",
      "${var.region}-docker.pkg.dev/${var.project_id}/${data.google_artifact_registry_repository.repository.repository_id}/${var.service_name}:latest"
    ]
  }
}

resource "google_cloud_scheduler_job" "daily_job" {
  name             = "${var.service_name}-daily"
  description      = "Triggers ${var.service_name} every day at midnight"
  schedule         = "0 0 * * *"
  time_zone        = "UTC"
  attempt_deadline = "320s"
  region           = var.region

  http_target {
    http_method = "GET"
    uri         = google_cloud_run_v2_service.service.uri

    oidc_token {
      service_account_email = google_service_account.service_sa.email
    }
  }
}
