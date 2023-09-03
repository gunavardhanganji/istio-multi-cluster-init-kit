
module "cluster-1" {
  source = "./modules/k8s-cluster"
  cluster_name = "cluster-1"
  location = "us-central1-c"
  project_id = "istio-setup"
}

module "cluster-1-node-pool" {
    source = "./modules/k8s-node-pool"
    node_pool_name = "cluster-1-node-pool"
    cluster_name = "cluster-1"
    location = "us-central1-c"
    machine_type = "n1-standard-2"
    service_account = "785799636758-compute@developer.gserviceaccount.com"
}