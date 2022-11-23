output "name" {
  value = google_service_account.myaccount.name
}

# output "key" {
#   value = google_service_account_key.mykey.private_key
#   sensitive = true
# }

# pool id
output "pool_id" {
  value = google_iam_workload_identity_pool.example.name
}

# registry id
output "registry_id" {
  value = google_container_registry.registry.id
}

# provider id
output "provider_id" {
  value = google_iam_workload_identity_pool_provider.example.name
}

# service account id
output "service_account_id" {
  value = google_service_account.myaccount.name
}