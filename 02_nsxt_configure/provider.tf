provider "nsxt" {
  username             = var.nsxt_username
  password             = var.nsxt_password
  host                 = var.nsxt_host
  allow_unverified_ssl = var.allow_unverified_ssl
}
provider "vsphere" {
  user                 = var.vsphere_user
  password             = var.vsphere_password
  vsphere_server       = var.vsphere_server
  allow_unverified_ssl = true
}

provider "avi" {
  avi_username         = var.avi_username
  avi_tenant           = var.avi_tenant
  avi_password         = var.avi_password
  avi_controller       = var.avi_controller
  avi_version          = "22.1.3"
}  
