# TF module for GKE cluster

resource "google_container_cluster" "primary" {
  name     = var.cluster_name
  location = var.location
  project = var.project_id

  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
#   machine_type = var.machine_type
  remove_default_node_pool = var.remove_default_node_pool
  initial_node_count       = var.initial_node_count
  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }
  
}