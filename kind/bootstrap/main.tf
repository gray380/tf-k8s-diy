resource "kind_cluster" "this" {
  name            = "kind-cluster"
  wait_for_ready  = true
  kubeconfig_path = "${path.module}/../kubeconfig"
}
