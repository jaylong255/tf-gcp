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

# Create a service account
# gcloud iam service-accounts create "my-service-account" \
#   --project "${PROJECT_ID}"
resource "google_service_account" "myaccount" {
    account_id   = "myaccount"
    display_name = "My Service Account"
    project = local.project_id
}

# make sure the iamcredentials service is enabled
# gcloud services enable iamcredentials.googleapis.com --project "${PROJECT_ID}"

# Create a workload identity pool
# gcloud iam workload-identity-pools create "my-pool" \
#   --location "${REGION}" \
#   --display-name "My Pool" \
#   --project "${PROJECT_ID}"
resource "google_iam_workload_identity_pool" "example" {
    workload_identity_pool_id = "example-pool"
    display_name              = "Name of pool"
    description               = "Identity pool for automated test"
    #   disabled                  = true
    project = local.project_id
}

# Create a workload identity pool provider
# gcloud iam workload-identity-pools providers create-oidc "my-pool-provider" \
#   --location "${REGION}" \
#   --workload-identity-pool "my-pool" \
#   --issuer-uri "https://token.actions.githubusercontent.com" \
#   --attribute-mapping="google.subject=assertion.sub,attribute.actor=assertion.actor,attribute.repository=assertion.repository" \
#   --project "${PROJECT_ID}"
resource "google_iam_workload_identity_pool_provider" "example" {
    project = local.project_number
    workload_identity_pool_provider_id = "example-provider3"
    workload_identity_pool_id = "example-pool"
    display_name = "Demo provider"
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

# Custom role
# gcloud iam roles create "MyRole" \
#   --project "${PROJECT_ID}" \
#   --permissions "iam.workloadIdentityPools.get" \
#   --title "My Role"

# Create a custom role
resource "google_project_iam_custom_role" "github_actions" {
    role_id     = "githubActionsGCR"
    title       = "Github Actions GCR"
    description = "Role for Github Actions to push images to GCR"
    permissions = [
        "storage.buckets.get"
    ]
    project = local.project_id
}

# Bind the service account to the workload identity pool
# gcloud iam service-accounts add-iam-policy-binding "my-service-account@${PROJECT_ID}.iam.gserviceaccount.com" \
#   --project="${PROJECT_ID}" \
#   --role="roles/iam.workloadIdentityUser" \
#   --member="principalSet://iam.googleapis.com/${WORKLOAD_IDENTITY_POOL_ID}/attribute.repository/${REPO}"
resource "google_service_account_iam_binding" "example" {
    service_account_id = google_service_account.myaccount.name
    # role = "roles/iam.workloadIdentityUser"
    role = google_project_iam_custom_role.github_actions.name
    
    members = [
        "principalSet://iam.googleapis.com/projects/${local.project_number}/locations/global/workloadIdentityPools/example-pool/attribute.repository/${local.repo}"
    ]
    # members = [
    #     "principalSet://iam.googleapis.com/example-pool/attribute.repository/hashbang-jmetal"
    # ]
    
}


# container registry
resource "google_container_registry" "registry" {
  project = local.project_id
}
