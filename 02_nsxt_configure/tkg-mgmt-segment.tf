resource "nsxt_policy_segment" "tkg-mgmt" {
  nsx_id              = "tkg-mgmt"
  display_name        = "tkg-mgmt"
  description         = "tkg-mgmt"
  connectivity_path   = nsxt_policy_tier1_gateway.tkg.path
  transport_zone_path = data.nsxt_policy_transport_zone.overlay_tz.path
  dhcp_config_path    = nsxt_policy_dhcp_server.tkg-dhcp.path

  subnet {
    cidr = "${var.tkg_mgmt_segment_prefix}.1/24"
    dhcp_ranges = ["${var.tkg_mgmt_segment_prefix}.2-${var.tkg_mgmt_segment_prefix}.200"]
    dhcp_v4_config {
      server_address = "${var.tkg_mgmt_segment_prefix}.254/24"
      dns_servers    = var.dns_servers
      lease_time     = 200
    }
  }
}

resource "nsxt_policy_nat_rule" "tkg-mgmt-no-snat-mgmt-vip" {
  display_name        = "no snat to mgmt vip segment"
  description         = "NO SNAT rule for all VMs in the tkg-mgmt"
  action              = "NO_SNAT"
  gateway_path        = nsxt_policy_tier1_gateway.tkg.path
  logging             = false
  source_networks     = ["${var.tkg_mgmt_segment_prefix}.0/24"]
  destination_networks = [var.tkg_vip_segment_subnet]
  translated_networks = []
  rule_priority       = 1
}


resource "nsxt_policy_nat_rule" "tkg-mgmt-dnat" {
  display_name        = "tkg-mgmt-dnat"
  description         = "DNAT rule for jumphost in tkg-mgmt"
  action              = "DNAT"
  gateway_path        = nsxt_policy_tier1_gateway.tkg.path
  logging             = false
  destination_networks = [var.tkg_mgmt_segment_nat_gateway_ip]
  translated_networks = ["${var.tkg_mgmt_segment_prefix}.254"]
  rule_priority       = 1
}

resource "nsxt_policy_nat_rule" "tkg-mgmt-snat" {
  display_name        = "tkg-mgmt-snat"
  description         = "SNAT rule for all VMs in the tkg-mgmt"
  action              = "SNAT"
  gateway_path        = nsxt_policy_tier1_gateway.tkg.path
  logging             = false
  source_networks     = ["${var.tkg_mgmt_segment_prefix}.0/24"]
  translated_networks = [var.tkg_mgmt_segment_nat_gateway_ip]
  rule_priority       = 1000
}
