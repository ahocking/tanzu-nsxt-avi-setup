variable "nsxt_host" {
  description = "The NSX-T Manager host. Must resolve to a reachable IP address, e.g. `nsxmgr.example.tld`"
  type        = string
}

variable "nsxt_username" {
  description = "The NSX-T username, probably `admin`"
  type        = string
}

variable "nsxt_password" {
  description = "The NSX-T password"
  type        = string
  sensitive   = true
}

variable "vsphere_user" {
  description = "The vsphere_user"
  type        = string
}

variable "vsphere_password" {
  description = "The vsphere password"
  type        = string
  sensitive   = true
}
variable "vsphere_server" {
  description = "The vsphere server"
  type        = string
}

variable "allow_unverified_ssl" {
  description = "Allow connection to NSX-T manager with self-signed certificates. Set to `true` for POC or development environments"
  default     = false
  type        = bool
}

variable "vsphere_datacenter_name" {
  description = "vsphere datacenter"
  type        = string
}

variable "vsphere_datastore_name" {
  description = "vsphere datastore for content library"
  type        = string
}

variable "vsphere_cluster_name" {
  type = string
  default = "vc01cl01"
}

variable "avi_controller_content_item_name" {
  description = "content library item name for the avi-controller ova"
  type        = string
}

variable "nsxt_edge_cluster_name" {
  default     = "edge-cluster-1"
  description = "The name of the edge cluster where the T1 gateways will be provisioned"
  type        = string
}

variable "nsxt_active_t0_gateway_name" {
  description = "The name of the T0 gateway where the T1s will be connected to"
  type        = string
}


variable "east_west_transport_zone_name" {
  description = "The name of the Transport Zone that carries internal traffic between the NSX-T components. Also known as the `overlay` transport zone"
  type        = string
}

variable "dns_servers" {
  description = "DNS servers"
  type = list(string)
}

variable "tkg_vip_segment_cidr" {
  description = "gateway CIDR for the tkg-vip"
  type        = string
}

variable "tkg_vip_segment_subnet" {
  description = "subnet CIDR for the tkg-vip"
  type        = string
}

variable "alb_management_segment_prefix" {
  description = "prefix for the avi mgmt network"
  type        = string
  default     = "192.168.1"
}

variable "alb_management_segment_nat_gateway_ip" {
  description = "The source IP address to use for all traffic leaving the avi mgmt network"
  type        = string
}

variable "tkg_mgmt_segment_prefix" {
  description = "prefix for the tkg-mgmt network"
  type        = string
  default     = "192.168.2"
}

variable "tkg_mgmt_segment_nat_gateway_ip" {
  description = "The source IP address to use for all traffic leaving the tkg-mgmt network"
  type        = string
}

variable "tkg_workload_segment_prefix" {
  description = "prefix for the tkg-work"
  type        = string
  default     = "192.168.3"
}

variable "tkg_workload_segment_nat_gateway_ip" {
  description = "The source IP address to use for all traffic leaving the tkg-work"
  type        = string
}

variable "tkg_ssc_segment_prefix" {
  description = "prefix for the tkg-ssc"
  type        = string
  default     = "192.168.4"
}

variable "tkg_ssc_segment_nat_gateway_ip" {
  description = "The source IP address to use for all traffic leaving the tkg-ssc"
  type        = string
}


variable "tkg_tap_segment_prefix" {
  description = "prefix for the tkg-tap"
  type        = string
  default     = "192.168.5"
}

variable "tkg_tap_segment_nat_gateway_ip" {
  description = "The source IP address to use for all traffic leaving the tkg-tap"
  type        = string
}

variable "avi_controller_ip" {
  type = string
}

variable "avi_controller_external_ip" {
  type = string
}

variable "ntp_server_ip_list" {
  type = list(string)
}

variable "avi_controller_vm_props" {
  default = {
    cpu = 8
    memory = 24768
    disk = 128
    wait_for_guest_net_timeout = 4
  }
}


