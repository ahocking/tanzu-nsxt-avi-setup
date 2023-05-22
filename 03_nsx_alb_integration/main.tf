terraform {
  required_providers {
    avi = {
      source  = "vmware/avi"
      version = "22.1.2"
    }
    vsphere = { source = "hashicorp/vsphere" }
    nsxt    = { source = "vmware/nsxt" }
    # vcd     = { source = "vmware/vcd" }

  }
}

provider "avi" {
  avi_username   = var.alb_username
  avi_tenant     = var.alb_tenant
  avi_password   = var.alb_password
  avi_controller = var.alb_controller
  avi_version    = var.alb_version
}

# provider "nsxt" {
#   host                 = var.nsx_manager
#   username             = var.nsx_user
#   password             = var.nsx_password
#   allow_unverified_ssl = true
# }

# provider "vsphere" {
#   user                 = var.vsphere_user
#   password             = var.vsphere_password
#   vsphere_server       = var.vsphere_server
#   allow_unverified_ssl = true
# }

# provider "vcd" {
#   user                 = var.vcd_user
#   password             = var.vcd_pass
#   auth_type            = "integrated"
#   url                  = "https://${var.vcd_url}/api"
#   org                  = "System"
#   allow_unverified_ssl = true
# }


# vCenter: Create Content Library
# Step 2 in https://www.virten.net/2021/10/getting-started-with-nsx-advanced-load-balancer-integration-in-vmware-cloud-director-10-3/
# data "vsphere_datacenter" "dc" { name = var.vc_datacenter }
# data "vsphere_compute_cluster" "cluster" {
#   name          = var.vc_cluster
#   datacenter_id = data.vsphere_datacenter.dc.id
# }
# data "vsphere_datastore" "datastore" {
#   name          = var.vc_datastore
#   datacenter_id = data.vsphere_datacenter.dc.id
# }

# #Create Content Library
# resource "vsphere_content_library" "library" {
#   name            = var.vc_contentlib
#   storage_backing = [data.vsphere_datastore.datastore.id]
# }

#NSX-T Create SE Management Network with DHCP
#Step 3 in https://www.virten.net/2021/10/getting-started-with-nsx-advanced-load-balancer-integration-in-vmware-cloud-director-10-3/
# data "nsxt_policy_transport_zone" "overlay" {
#   display_name = var.nsx_overlay_tz
# }
# data "nsxt_policy_edge_cluster" "ec" {
#   display_name = var.nsx_edgecluster
# }
# data "nsxt_policy_tier0_gateway" "t0" {
#   display_name = var.nsx_tier0
# }

# # Create DHCP Server Profile for Service Engine Network
# resource "nsxt_policy_dhcp_server" "alb" {
#   display_name      = "dhcp"
#   edge_cluster_path = data.nsxt_policy_edge_cluster.ec.path
# }

# Create Tier-1 Gateway and Segment for Service Engines. The upstream Tier-0 must exist and the configured network must be routable from the ALB Controller.
# resource "nsxt_policy_tier1_gateway" "tkg" {
#   display_name              = "tkg"
#   edge_cluster_path         = data.nsxt_policy_edge_cluster.ec.path
#   tier0_path                = data.nsxt_policy_tier0_gateway.t0.path
#   route_advertisement_types = ["TIER1_STATIC_ROUTES", "TIER1_CONNECTED"]
#   dhcp_config_path          = nsxt_policy_dhcp_server.alb.path
# }

# resource "nsxt_policy_segment" "tkg-alb" {
#   display_name        = "tkg-alb"
#   connectivity_path   = nsxt_policy_tier1_gateway.tkg.path
#   transport_zone_path = data.nsxt_policy_transport_zone.overlay.path
#   subnet {
#     cidr        = "10.184.142.1/24"
#     dhcp_ranges = ["10.184.142.100-10.184.142.150"]
#   }
# }

# Dummy Tier-1 and Segment, required for the initial NSX-T Cloud configuration in NSX-ALB.
# resource "nsxt_policy_tier1_gateway" "tkg" {
#   display_name              = "tkg"
#   edge_cluster_path         = data.nsxt_policy_edge_cluster.ec.path
#   tier0_path                = data.nsxt_policy_tier0_gateway.t0.path
#   route_advertisement_types = []
# }
# resource "nsxt_policy_segment" "tkg-mgmt" {
#   display_name        = "tkg-mgmt"
#   connectivity_path   = nsxt_policy_tier1_gateway.tkg.path
#   transport_zone_path = data.nsxt_policy_transport_zone.overlay.path
#   subnet {
#     cidr = "10.184.140.1/24"
#     dhcp_ranges = ["10.184.140.100-10.184.140.150"]
#   }
# }
# resource "nsxt_policy_segment" "tkg-ssc" {
#   display_name        = "tkg-ssc"
#   connectivity_path   = nsxt_policy_tier1_gateway.tkg.path
#   transport_zone_path = data.nsxt_policy_transport_zone.overlay.path
#   subnet {
#     cidr = "10.184.141.1/24"
#     dhcp_ranges = ["10.184.141.100-10.184.141.150"]
#   }
# }
# resource "nsxt_policy_segment" "tkg-work" {
#   display_name        = "tkg-work"
#   connectivity_path   = nsxt_policy_tier1_gateway.tkg.path
#   transport_zone_path = data.nsxt_policy_transport_zone.overlay.path
#   subnet {
#     cidr = "10.184.144.1/24"
#     dhcp_ranges = ["10.184.144.100-10.184.144.150"]
#   }
# }

# data "nsxt_policy_transport_zone" "nsx-tr-zone" {
#   display_name = var.nsx_overlay_tz
# }
# NSX-ALB: Create NSX-T Cloud
# Step 4 in https://www.virten.net/2021/10/getting-started-with-nsx-advanced-load-balancer-integration-in-vmware-cloud-director-10-3/

# ALB Users for vCenter and NSX-T
resource "avi_cloudconnectoruser" "vcenter" {
  name = "vcenter"
  vcenter_credentials {
    username = var.vsphere_user
    password = var.vsphere_password
 }
}
resource "avi_cloudconnectoruser" "nsx" {
  name = "nsxt-cloud"
  nsxt_credentials {
    username = var.nsx_user
    password = var.nsx_password
  }
  lifecycle { ignore_changes = [nsxt_credentials] }
}

# Create NSX-T Cloud
resource "avi_cloud" "nsx" {
  name            = "nsxt-cloud"
  vtype           = "CLOUD_NSXT"
  dhcp_enabled    = true
  obj_name_prefix = "nsx-t"
  nsxt_configuration {
    nsxt_url             = var.nsx_manager
    nsxt_credentials_ref = avi_cloudconnectoruser.nsx.id
    management_network_config {
      transport_zone = var.nsx_overlay_tz
      tz_type        = "OVERLAY"
      overlay_segment {
        tier1_lr_id = var.nsx_tier1
        segment_id  = var.nsx_tkg_alb_segment
      }
    }
    data_network_config {
      transport_zone = var.nsx_overlay_tz
      tz_type        = "OVERLAY"
      tier1_segment_config {
        segment_config_mode = "TIER1_SEGMENT_MANUAL"
        manual { 
         tier1_lrs {
            tier1_lr_id = var.nsx_tier1
            segment_id  = var.nsx_tkg_mgmt_segment
         }
        }
        manual {
         tier1_lrs {
            tier1_lr_id = var.nsx_tier1
            segment_id  = var.nsx_tkg_ssc_segment
          } 
        }
      }
    }
  }
}
resource "avi_vcenterserver" "vcenter" {
  name = "vcenter"
  vcenter_url             = var.vsphere_server
  vcenter_credentials_ref = avi_cloudconnectoruser.vcenter.id
  cloud_ref               = avi_cloud.nsx.id
  content_lib {
    id = var.vc_contentlib
  }
}

#NSX-ALB: Create Service Engine Group
#Step 5 in https://www.virten.net/2021/10/getting-started-with-nsx-advanced-load-balancer-integration-in-vmware-cloud-director-10-3/

# resource "avi_serviceenginegroup" "nsxt-se" {
#   name           = "nsxt-se"
#   se_name_prefix = "nsxt"
#   ha_mode        = "HA_MODE_SHARED" # (Elastic HA N+M Buffer)
#   algo           = "PLACEMENT_ALGO_PACKED"
#   max_se         = 10
#   max_vs_per_se  = 10
#   cloud_ref      = avi_cloud.nsx.id
#   vcenters {
#     vcenter_ref = avi_vcenterserver.vcenter.id
#     nsxt_datastores {
#       include = true
#       ds_ids  = [data.vsphere_datastore.datastore.id]
#     }
#     nsxt_clusters {
#       include     = true
#       cluster_ids = [data.vsphere_compute_cluster.cluster.id]
#     }
#   }
# }

# Add ALB Controller and Service Engine Group to Cloud Director
# Step 6 in https://www.virten.net/2021/10/getting-started-with-nsx-advanced-load-balancer-integration-in-vmware-cloud-director-10-3/

# Add NSX-T ALB Controller to VCD. Must use a valid and trusted certificate.
# resource "vcd_nsxt_alb_controller" "alb" {
#   name         = var.alb_controller
#   url          = "https://${var.alb_controller}"
#   username     = var.alb_username
#   password     = var.alb_password
#   license_type = "ENTERPRISE"
# }

# # Helper Datasoure to grab Cloud ID and Network Pool for NSX-T Cloud
# data "vcd_nsxt_alb_importable_cloud" "nsx" {
#   name          = avi_cloud.nsx.name
#   controller_id = vcd_nsxt_alb_controller.alb.id
# }

# # Import ALB NSX-T Cloud
# resource "vcd_nsxt_alb_cloud" "nsx" {
#   name                = var.nsx_manager
#   controller_id       = vcd_nsxt_alb_controller.alb.id
#   importable_cloud_id = data.vcd_nsxt_alb_importable_cloud.nsx.id
#   network_pool_id     = data.vcd_nsxt_alb_importable_cloud.nsx.network_pool_id
# }

# # Import Service Engine Group as Shared SEG
# resource "vcd_nsxt_alb_service_engine_group" "sseg_01" {
#   name                                 = "${split(".", var.nsx_manager)[0]}-seg-01"
#   alb_cloud_id                         = vcd_nsxt_alb_cloud.nsx.id
#   importable_service_engine_group_name = "${split(".", var.nsx_manager)[0]}-seg-01"
#   reservation_model                    = "SHARED"
#   sync_on_refresh                      = false
# }
