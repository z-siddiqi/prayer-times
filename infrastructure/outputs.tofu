output "service_url" {
  description = "The URL of the deployed Cloud Run service"
  value       = google_cloud_run_v2_service.service.uri
}

output "service_name" {
  description = "The name of the deployed Cloud Run service"
  value       = google_cloud_run_v2_service.service.name
}

output "service_status" {
  description = "The status of the Cloud Run service"
  value       = google_cloud_run_v2_service.service.latest_ready_revision
}

output "scheduler_job" {
  description = "The Cloud Scheduler job that triggers the service daily at midnight"
  value       = google_cloud_scheduler_job.daily_job.name
}

output "scheduler_job_schedule" {
  description = "The schedule for the Cloud Scheduler job"
  value       = google_cloud_scheduler_job.daily_job.schedule
}
