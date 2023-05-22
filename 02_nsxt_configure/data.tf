data "nsxt_policy_transport_zone" "overlay_tz" {
  display_name = var.east_west_transport_zone_name
}

data "nsxt_policy_edge_cluster" "ec" {
  display_name = var.nsxt_edge_cluster_name
}

data "nsxt_policy_tier0_gateway" "nsxt_active_t0_gateway" {
  display_name = var.nsxt_active_t0_gateway_name
}

data "vsphere_datacenter" "datacenter" {
  name = var.vsphere_datacenter_name
}

data "vsphere_datastore" "datastore" {
  name          = var.vsphere_datastore_name
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

data "vsphere_compute_cluster" "cluster" {
  name          = var.vsphere_cluster_name
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

data "vsphere_resource_pool" "default" {
  name          = format("%s%s", data.vsphere_compute_cluster.cluster.name, "/Resources")
  datacenter_id = data.vsphere_datacenter.datacenter.id
}
