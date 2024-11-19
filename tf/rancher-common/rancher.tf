# Rancher resources

# Initialize Rancher server
resource "rancher2_bootstrap" "admin" {
  depends_on = [
    helm_release.rancher_server
  ]

  timeouts {
    create = "5m"
  }
  provider = rancher2.bootstrap

  password  = var.admin_password
  telemetry = true
}

# Create custom managed cluster for troublemaker
resource "rancher2_cluster_v2" "troublemaker_workload" {
  provider = rancher2.admin

  name               = var.workload_cluster_name
  kubernetes_version = var.workload_kubernetes_version
}
