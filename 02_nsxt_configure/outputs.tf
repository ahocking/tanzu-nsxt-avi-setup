output "transport_zone_id" {
  value = data.nsxt_policy_transport_zone.overlay_tz.id
}

output "jumpbox_routable_ip" {
  value = var.tkg_mgmt_segment_nat_gateway_ip
}
