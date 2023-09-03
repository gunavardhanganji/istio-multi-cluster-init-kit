terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "4.80.0"
    }
  }
}

provider "google" {
  credentials = file("../sa-keys/istiosetup-6fb645a43e5e.json")
  project = "istiosetup"
}
