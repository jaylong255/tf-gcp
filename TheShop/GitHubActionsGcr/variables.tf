variable "project_id" {
    description = "The unique string ID of your Google Cloud project."
    type        = string
}

variable "region" {
    description = "The region to deploy to."
    type        = string
}

variable "zone" {
    description = "The zone to deploy to."
    type        = string
}

variable "project_number" {
    description = "The unique numeric ID of your Google Cloud project."
    type        = number
}

variable "repo" {
    description = "The name of the repo to create."
    type        = string
}

variable "admin_email" {
    description = "The email of the admin user."
    type        = string
}