variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "region" {
  description = "The GCP region to deploy resources"
  type        = string
  default     = "europe-west1"
}

variable "service_name" {
  description = "The name of the Cloud Run service"
  type        = string
  default     = "calendar-service"
}

variable "github_repo_name" {
  description = "The name of the GitHub repository"
  type        = string
}

variable "calendar_id" {
  description = "The ID of the Google Calendar to create events in"
  type        = string
  sensitive   = true
}
