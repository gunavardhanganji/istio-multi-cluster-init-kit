variable "node_pool_name" {
  type = string
  description = "Name of the node-pool to be attached to cluster"
}
variable "cluster_name" {
  type = string
  description = "The name of the cluster, unique within the project and location"
}
# variable "project_id" {
#   type = string
#   description = "The name of the project in which GKE cluster is to be created"
# }
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

variable "node_count" {
  type = number
  description = <<EOF
  The number of nodes per instance group. This field can be used to update the number of nodes per instance group 
  but should not be used alongside autoscaling
  EOF
  default = 1
}

variable "preemptible" {
    type = bool
    default = true
}

variable "service_account" {
  type = string
  description = "The service account with which the node-pool has to be created"
}