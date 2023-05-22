# resource "vsphere_content_library_item" "avi_controller_file" {
#   name        = "avi-controller.ova"
#   library_id  = data.vsphere_content_library.avi_content_library.id
#   file_url = var.avi_controller_file
# }

resource "nsxt_policy_nat_rule" "avi-controller-dnat" {
  display_name        = "avi-controller-dnat"
  description         = "DNAT rule for avi-controller"
  action              = "DNAT"
  gateway_path        = nsxt_policy_tier1_gateway.tkg.path
  logging             = false
  destination_networks = [var.avi_controller_external_ip]
  translated_networks = [var.avi_controller_ip]
  rule_priority       = 1
}

data "vsphere_content_library_item" "avi_controller_file" {
    name = var.avi_controller_content_item_name
    type = "ova"
    library_id  = data.vsphere_content_library.avi_content_library.id
}

resource "vsphere_virtual_machine" "controller_static_standalone" {
  name             = "avi-controller"
#   folder = var.vcenter_folder == null ? null : vsphere_folder.folder[0].path
  datastore_id     = data.vsphere_datastore.datastore.id
  resource_pool_id = data.vsphere_resource_pool.default.id
  #folder           = var.folder_name

  network_interface {
    network_id = data.vsphere_network.alb-management-network.id
  }

  num_cpus = var.avi_controller_vm_props.cpu
  memory = var.avi_controller_vm_props.memory
  wait_for_guest_net_timeout = var.avi_controller_vm_props.wait_for_guest_net_timeout
  guest_id = "ubuntu64Guest"
  # guest_id = "guest-id"


  disk {
    size             = var.avi_controller_vm_props.disk
    label            = "avi-controller.lab_vmdk"
    thin_provisioned = true
  }

  clone {
    template_uuid = data.vsphere_content_library_item.avi_controller_file.id
  }

  vapp {
    properties = {
      "mgmt-ip"     = var.avi_controller_ip
      "mgmt-mask"   = "255.255.255.0"
      "default-gw"  = "${var.alb_management_segment_prefix}.1"
    }
  }
}


resource "null_resource" "wait_https_controller_static_standalone" {
  depends_on = [vsphere_virtual_machine.controller_static_standalone]

  provisioner "local-exec" {
    command = "until $(curl --output /dev/null --silent --head -k https://${var.avi_controller_external_ip}); do echo 'Waiting for Avi Controllers to be ready'; sleep 10 ; done"
  }
}

# resource "local_file" "output_json_file_avi_config" {
#   content     = "{\"avi_version\": ${jsonencode(var.avi_version)}, \"avi_tenant\": ${jsonencode(var.avi_tenant)}, \"avi_current_password\": ${jsonencode(var.avi_current_password)}, \"avi_cluster\": ${jsonencode(var.avi_cluster)}, \"avi_dns_server_ips\": ${jsonencode(var.avi_dns_server_ips)}, \"avi_ntp_server_ips\": ${jsonencode(var.avi_ntp_server_ips)}, \"deployment_id\": ${jsonencode(random_string.id.result)}, \"avi_default_license_tier\": ${jsonencode(var.avi_default_license_tier)}}"
#   filename = "../avi_config.json"
# }

# resource "local_file" "output_json_file_static_standalone" {
#   content     = "{\"avi_controller_ips\": ${jsonencode(vsphere_virtual_machine.controller_static_standalone.*.default_ip_address)}}"
#   filename = "../controllers.json"
# }