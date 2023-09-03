terraform {
  backend "gcs" {
    bucket  = "terraform-state-istiosetup"
    prefix  = "terraform/state"
  }
}