resource "nsxt_policy_segment" "tkg-vip" {
  nsx_id              = "tkg-vip"
  display_name        = "tkg-vip"
  description         = "tkg-vip Network Segment"
  connectivity_path   = nsxt_policy_tier1_gateway.tkg.path
  transport_zone_path = data.nsxt_policy_transport_zone.overlay_tz.path

  subnet {
    cidr = var.tkg_vip_segment_cidr
  }
}
