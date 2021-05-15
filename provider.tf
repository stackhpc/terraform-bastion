terraform {
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "1.40.0"
    }
  }

  backend "remote" {
    hostname     = "app.terraform.io"
    organization = "stackhpc"

    workspaces {
      prefix = "bastion-"
    }
  }
}

provider "openstack" {
  cloud = "openstack"
}
