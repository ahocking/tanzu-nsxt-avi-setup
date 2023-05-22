terraform {
    required_providers {
      nsxt = {
          source = "vmware/nsxt"
          version = "3.3.0"
      }
      avi = {
        source  = "vmware/avi"
        version = "21.1.1"
      }
    }

    required_version = ">=1.0.0"
}