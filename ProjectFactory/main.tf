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

# create a folder
resource "google_folder" "folder" {
  display_name = "Test Folder One"
  parent       = "organizations/${var.org_id}"
}

# module "test_project_1" {
#     id = "test-project-1"
#     name = "The First Project Yo"
#     org_id = var.org_id
#     # source = "github.com/terraform-google-modules/terraform-google-project-factory"
#     source = "../Modules/Project"
# }