terraform {
  required_providers {
    openstack = {
      source = "terraform-provider-openstack/openstack"
      version = "1.40.0"
    }
  }
}

provider "openstack" {
  cloud = "vglab"
}
