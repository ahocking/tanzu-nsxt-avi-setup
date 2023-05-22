resource "nsxt_policy_dhcp_server" "tkg-dhcp" {
  display_name      = "tkg-dhcp"
  description       = "Terraform provisioned DhcpServerConfig"
  edge_cluster_path = data.nsxt_policy_edge_cluster.ec.path
  lease_time        = 200
}