resource "nsxt_policy_segment" "tkg-alb" {
  nsx_id              = "tkg-alb"
  display_name        = "tkg-alb"
  description         = "tkg-alb"
  connectivity_path   = nsxt_policy_tier1_gateway.tkg.path
  transport_zone_path = data.nsxt_policy_transport_zone.overlay_tz.path
  dhcp_config_path    = nsxt_policy_dhcp_server.tkg-dhcp.path

  subnet {
    cidr = "${var.alb_management_segment_prefix}.1/24"
    dhcp_ranges = ["${var.alb_management_segment_prefix}.2-${var.alb_management_segment_prefix}.200"]
    dhcp_v4_config {
      server_address = "${var.alb_management_segment_prefix}.254/24"
      dns_servers    = var.dns_servers
      lease_time     = 365
    }
  }
}


data "nsxt_policy_segment_realization" "alb_management_segment_realization" {
  path = nsxt_policy_segment.tkg-alb.path
}

# usage in vsphere provider
data "vsphere_network" "alb-management-network" {
  name          = data.nsxt_policy_segment_realization.alb_management_segment_realization.network_name
  datacenter_id = data.vsphere_datacenter.datacenter.id
}


resource "nsxt_policy_nat_rule" "tkg-alb-snat" {
  display_name        = "tkg-alb-snat"
  description         = "SNAT rule for all VMs in the tkg-alb"
  action              = "SNAT"
  gateway_path        = nsxt_policy_tier1_gateway.tkg.path
  logging             = false
  source_networks     = ["${var.alb_management_segment_prefix}.0/24"]
  translated_networks = [var.alb_management_segment_nat_gateway_ip]
  rule_priority       = 1000
}
