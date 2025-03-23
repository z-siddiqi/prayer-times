terraform {
  backend "gcs" {
    bucket = "prayer-times-454617-infrastructure-state"
    prefix = "calendar-service"
  }
}
