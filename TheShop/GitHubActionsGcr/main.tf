terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "4.44.1"
    }
  }
}

provider "google" {
  # Configuration options
}

locals {
    project_id = var.project_id
    region = var.region
    zone = var.zone
    project_number = var.project_number
    repo = var.repo
}

data "google_iam_policy" "admin" {
  binding {
    role = "roles/containerregistry.ServiceAgent"

    members = [
      "serviceAccount:service-${var.project_number}@containerregistry.iam.gserviceaccount.com",
    ]
  }

  binding {
    role = "roles/iam.serviceAccountOpenIdTokenCreator"

    members = [
      "user:${var.admin_email}",
    ]
  }

  binding {
    role = "roles/iam.serviceAccountTokenCreator"

    members = [
      "user:${var.admin_email}",
    ]
  }

  binding {
    role = "roles/owner"

    members = [
      "user:${var.admin_email}",
    ]
  }

  binding {
    role = "roles/pubsub.serviceAgent"

    members = [
      "serviceAccount:service-678101462758@gcp-sa-pubsub.iam.gserviceaccount.com"
    ]
  }

  binding {
    role = "roles/storage.admin"

    members = [
      "user:${var.admin_email}",
    ]
  }

  binding {
    role = "roles/storage.objectAdmin"

    members = [
      "user:${var.admin_email}",
    ]
  }

}

resource "google_project_iam_policy" "project" {
  project     = local.project_id
  policy_data = data.google_iam_policy.admin.policy_data
}

# Create a service account
# gcloud iam service-accounts create "my-service-account" \
#   --project "${PROJECT_ID}"
resource "google_service_account" "github_actions_gcr" {
    project       = local.project_id
    account_id    = "github-actions-gcr"
    display_name  = "Github Actions GCR"
}

# make sure the iamcredentials service is enabled
# gcloud services enable iamcredentials.googleapis.com --project "${PROJECT_ID}"

# Create a workload identity pool
# gcloud iam workload-identity-pools create "my-pool" \
#   --location "${REGION}" \
#   --display-name "My Pool" \
#   --project "${PROJECT_ID}"
resource "google_iam_workload_identity_pool" "github_actions_gcr" {
    project                   = local.project_id
    workload_identity_pool_id = "github-actions-gcr-pool"
    display_name              = "Github Actions GCR Pool"
    description               = "Github Actions GCR Pool"    
}

# Create a workload identity pool provider
# gcloud iam workload-identity-pools providers create-oidc "my-pool-provider" \
#   --location "${REGION}" \
#   --workload-identity-pool "my-pool" \
#   --issuer-uri "https://token.actions.githubusercontent.com" \
#   --attribute-mapping="google.subject=assertion.sub,attribute.actor=assertion.actor,attribute.repository=assertion.repository" \
#   --project "${PROJECT_ID}"
resource "google_iam_workload_identity_pool_provider" "github_actions_gcr" {
    project = local.project_number
    workload_identity_pool_id = google_iam_workload_identity_pool.github_actions_gcr.workload_identity_pool_id
    workload_identity_pool_provider_id = "github-actions-gcr-provider"    
    display_name = "Github Actions GCR Provider"
    disabled = false
    attribute_mapping = {
        "google.subject" = "assertion.sub"
        "attribute.actor" = "assertion.actor"
        "attribute.repository" = "assertion.repository"
    }
    oidc {
        issuer_uri = "https://token.actions.githubusercontent.com"
    }
}

# Make sure iamcredentials service is enabled
# gcloud services enable iamcredentials.googleapis.com \
#   --project "${PROJECT_ID}"

# Custom role
# gcloud iam roles create "MyRole" \
#   --project "${PROJECT_ID}" \
#   --permissions "iam.workloadIdentityPools.get" \
#   --title "My Role"

# Bind the service account to the workload identity pool
# gcloud iam service-accounts add-iam-policy-binding "my-service-account@${PROJECT_ID}.iam.gserviceaccount.com" \
#   --project="${PROJECT_ID}" \
#   --role="roles/iam.serviceAccountTokenCreator" \
#   --member="serviceAccount:${google_service_account.github_actions_gcr.email}"
resource "google_service_account_iam_binding" "token_creator" {
    service_account_id = google_service_account.github_actions_gcr.name
    role = "roles/iam.serviceAccountTokenCreator"
    
    members = [
      "serviceAccount:${google_service_account.github_actions_gcr.email}"
    ]
}

# Bind the service account to the workload identity pool
# gcloud iam service-accounts add-iam-policy-binding "my-service-account@${PROJECT_ID}.iam.gserviceaccount.com" \
#   --project="${PROJECT_ID}" \
#   --role="roles/iam.workloadIdentityUser" \
#   --member="principalSet://iam.googleapis.com/${WORKLOAD_IDENTITY_POOL_ID}/attribute.repository/${REPO}"
resource "google_service_account_iam_binding" "workload_identity_provider" {
    service_account_id = google_service_account.github_actions_gcr.name
    role = "roles/iam.workloadIdentityUser"
    
    members = [
      "principalSet://iam.googleapis.com/projects/${local.project_number}/locations/global/workloadIdentityPools/${google_iam_workload_identity_pool.github_actions_gcr.workload_identity_pool_id}/attribute.repository/${local.repo}"
    ]
}

# Container Registry
resource "google_container_registry" "registry" {
  project = local.project_id
}

# Bind roles that allow the service account to push and pull images to the registry
data "google_iam_policy" "registry_bucket" {
  binding {
    role = "roles/storage.objectViewer"
    members = [
      "serviceAccount:${google_service_account.github_actions_gcr.email}"
    ]
  }

  binding {
    role = "roles/storage.legacyBucketWriter"
    members = [
      "serviceAccount:${google_service_account.github_actions_gcr.email}"
    ]
  }
}

resource "google_storage_bucket_iam_policy" "policy" {
  bucket = google_container_registry.registry.id
  policy_data = data.google_iam_policy.registry_bucket.policy_data
}

