# provider id
output "WORKLOAD_IDENTITY_PROVIDER" {
  value = google_iam_workload_identity_pool_provider.github_actions_gcr.name
}

# service account id
output "SERVICE_ACCOUNT" {
  value = google_service_account.github_actions_gcr.name
}

# service account email
output "SERVICE_ACCOUNT_EMAIL" {
  value = google_service_account.github_actions_gcr.email
}

# registry bucket id
output "REGISTRY_BUCKET" {
  value = google_container_registry.registry.id
}

# bucket self link
output "REGISTRY_BUCKET_SELF_LINK" {
  value = google_container_registry.registry.bucket_self_link
}