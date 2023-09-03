
module "cluster-1" {
  source = "./modules/k8s-cluster"
  cluster_name = "cluster-1"
  location = "us-central1-c"
  project_id = "istiosetup"
}

module "cluster-1-node-pool" {
    source = "./modules/k8s-node-pool"
    node_pool_name = "cluster-1-node-pool"
    cluster_name = "module.cluster-1.cluster_name"
    location = "us-central1-c"
    machine_type = "n1-standard-2"
    service_account = "k8s-sa@istiosetup.iam.gserviceaccount.com"
}

module "cluster-2" {
  source = "./modules/k8s-cluster"
  cluster_name = "cluster-2"
  location = "us-east1-b"
  project_id = "istiosetup"
}

module "cluster-2-node-pool" {
    source = "./modules/k8s-node-pool"
    node_pool_name = "cluster-2-node-pool"
    cluster_name = "module.cluster-2.cluster_name"
    location = "us-east1-b"
    machine_type = "n1-standard-2"
    service_account = "k8s-sa@istiosetup.iam.gserviceaccount.com"
}