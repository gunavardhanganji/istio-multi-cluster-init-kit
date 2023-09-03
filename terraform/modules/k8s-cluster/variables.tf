variable "cluster_name" {
  type = string
  description = "The name of the cluster, unique within the project and location"
}
variable "project_id" {
  type = string
  description = "The name of the project in which GKE cluster is to be created"
}
variable "location" {
  type = string
  description = <<EOF
  The location (region or zone) in which the cluster master will be created,
  as well as the default node location. If you specify a zone (such as us-central1-a), 
  the cluster will be a zonal cluster with a single cluster master. 
  If you specify a region (such as us-west1), the cluster will be a regional cluster with multiple masters 
  spread across zones in the region, and with default node locations in those zones as well
  EOF
}

variable "machine_type" {
    type = string
    description = <<EOF
        The name of a Google Compute Engine machine type. Defaults to e2-medium
    EOF
    default = "e2-medium"
}
variable "remove_default_node_pool" {
  type = bool
  description = <<EOF
   If true, deletes the default node pool upon cluster creation. If you're using google_container_node_pool 
   resources with no default node pool, this should be set to true, alongside setting initial_node_count to at least 1.
   EOF
  default = true
}

variable "initial_node_count" {
  type = number
  description = <<EOF
    (Optional) The number of nodes to create in this cluster's default node pool. 
    In regional or multi-zonal clusters, this is the number of nodes per zone. 
    Must be set if node_pool is not set. If you're using google_container_node_pool objects with no default node pool,
    you'll need to set this to a value of at least 1, alongside setting remove_default_node_pool to true
  EOF
  default = 1
}