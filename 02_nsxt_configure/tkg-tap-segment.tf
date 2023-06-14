resource "nsxt_policy_segment" "tkg-tap" {
  nsx_id              = "tkg-tap"
  display_name        = "tkg-tap"
  description         = "tkg-tap"
  connectivity_path   = nsxt_policy_tier1_gateway.tkg.path
  transport_zone_path = data.nsxt_policy_transport_zone.overlay_tz.path
  dhcp_config_path    = nsxt_policy_dhcp_server.tkg-dhcp.path

  subnet {
    cidr = "${var.tkg_tap_segment_prefix}.1/24"
    dhcp_ranges = ["${var.tkg_tap_segment_prefix}.2-${var.tkg_tap_segment_prefix}.200"]
    dhcp_v4_config {
      server_address = "${var.tkg_tap_segment_prefix}.254/24"
      dns_servers    = var.dns_servers
      lease_time     = 200

      # NTP
      dhcp_generic_option {
        code         = "42"
        values       = var.ntp_server_ip_list
      }
    }
  }
}

resource "nsxt_policy_nat_rule" "tkg-tap-no-snat-mgmt-vip" {
  display_name        = "no snat to mgmt vip"
  description         = "NO SNAT rule for all VMs in the tkg-tap to mangement vip segment"
  action              = "NO_SNAT"
  gateway_path        = nsxt_policy_tier1_gateway.tkg.path
  logging             = false
  source_networks     = ["${var.tkg_tap_segment_prefix}.0/24"]
  destination_networks = [var.tkg_vip_segment_subnet]
  translated_networks = []
  rule_priority       = 1
}


resource "nsxt_policy_nat_rule" "tkg-tap-snat" {
  display_name        = "tkg-tap-snat"
  description         = "SNAT rule for all VMs in the tkg-tap"
  action              = "SNAT"
  gateway_path        = nsxt_policy_tier1_gateway.tkg.path
  logging             = false
  source_networks     = ["${var.tkg_tap_segment_prefix}.0/24"]
  translated_networks = [var.tkg_tap_segment_nat_gateway_ip]
  rule_priority       = 1000
}
