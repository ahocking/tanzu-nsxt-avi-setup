resource "nsxt_policy_tier1_gateway" "tkg" {
  nsx_id                    = "tkg"
  description               = "Tier-1 Gateway for tkg"
  display_name              = "tkg"
  failover_mode             = "NON_PREEMPTIVE"
  enable_standby_relocation = true
  edge_cluster_path         = data.nsxt_policy_edge_cluster.ec.path
  tier0_path                = data.nsxt_policy_tier0_gateway.nsxt_active_t0_gateway.path
  route_advertisement_types = ["TIER1_STATIC_ROUTES", "TIER1_CONNECTED", "TIER1_NAT", "TIER1_LB_VIP", "TIER1_LB_SNAT","TIER1_DNS_FORWARDER_IP","TIER1_IPSEC_LOCAL_ENDPOINT"]
  pool_allocation           = "ROUTING"
}