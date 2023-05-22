resource "nsxt_policy_segment" "tkg-ssc" {
  nsx_id              = "tkg-ssc"
  display_name        = "tkg-ssc"
  description         = "tkg-ssc"
  connectivity_path   = nsxt_policy_tier1_gateway.tkg.path
  transport_zone_path = data.nsxt_policy_transport_zone.overlay_tz.path
  dhcp_config_path    = nsxt_policy_dhcp_server.tkg-dhcp.path

  subnet {
    cidr = "${var.tkg_ssc_segment_prefix}.1/24"
    dhcp_ranges = ["${var.tkg_ssc_segment_prefix}.2-${var.tkg_ssc_segment_prefix}.200"]
    dhcp_v4_config {
      server_address = "${var.tkg_ssc_segment_prefix}.254/24"
      dns_servers    = var.dns_servers
      lease_time     = 200
    }
  }
}

resource "nsxt_policy_nat_rule" "tkg-ssc-no-snat-mgmt-vip" {
  display_name        = "no snat to mgmt vip"
  description         = "NO SNAT rule for all VMs in the tkg-ssc to mangement vip segment"
  action              = "NO_SNAT"
  gateway_path        = nsxt_policy_tier1_gateway.tkg.path
  logging             = false
  source_networks     = ["${var.tkg_ssc_segment_prefix}.0/24"]
  destination_networks = [var.tkg_vip_segment_subnet]
  translated_networks = []
  rule_priority       = 1
}

resource "nsxt_policy_nat_rule" "tkg-ssc-no-snat-workload-vip" {
  display_name        = "no snat to workload vip segment"
  description         = "NO SNAT rule for all VMs in the tkg-ssc to tkg-sscload-vip-segment"
  action              = "NO_SNAT"
  gateway_path        = nsxt_policy_tier1_gateway.tkg.path
  logging             = false
  source_networks     = ["${var.tkg_ssc_segment_prefix}.0/24"]
  destination_networks = [var.tkg_vip_segment_subnet]
  translated_networks = []
  rule_priority       = 1
}

resource "nsxt_policy_nat_rule" "tkg-ssc-snat" {
  display_name        = "tkg-ssc-snat"
  description         = "SNAT rule for all VMs in the tkg-ssc"
  action              = "SNAT"
  gateway_path        = nsxt_policy_tier1_gateway.tkg.path
  logging             = false
  source_networks     = ["${var.tkg_ssc_segment_prefix}.0/24"]
  translated_networks = [var.tkg_ssc_segment_nat_gateway_ip]
  rule_priority       = 1000
}
