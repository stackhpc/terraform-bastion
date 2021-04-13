data "openstack_compute_flavor_v2" "small" {
  name = "general.v1.small"
}

data "openstack_images_image_v2" "ubuntu" {
  name        = "Ubuntu-20.04"
}

data "openstack_networking_network_v2" "ovn_network" {
  name     = "ovn-network"
}

resource "openstack_networking_port_v2" "ovn_network" {
  name           = "bastion-ovn-network"
  network_id     = data.openstack_networking_network_v2.ovn_network.id
  admin_state_up = "true"
}

data "openstack_networking_floatingip_v2" "fip" {
  address = "185.45.78.150"
}

resource "openstack_networking_floatingip_associate_v2" "fip" {
  floating_ip = "185.45.78.150"
  port_id     = openstack_networking_port_v2.ovn_network.id
}

resource "openstack_compute_instance_v2" "bastion" {
  name            = "bastion"
  image_id        = data.openstack_images_image_v2.ubuntu.id
  flavor_id       = data.openstack_compute_flavor_v2.small.id
  key_pair        = "bharat-mac"
  security_groups = ["default"]

  network {
    port = openstack_networking_port_v2.ovn_network.id
  }
}

resource "null_resource" "users" {
  for_each = fileset("${path.module}/authorized_keys", "*")

  connection {
    user        = "ubuntu"
    host        = openstack_networking_floatingip_associate_v2.fip.floating_ip
  }

  provisioner "file" {
    source      = "authorized_keys/${each.key}"
    destination = "/tmp/${each.key}"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo useradd -m -s /bin/bash ${each.key}",
      "sudo mkdir -p /home/${each.key}/.ssh/",
      "sudo chown ${each.key}:${each.key} /home/${each.key}/.ssh/",
      "sudo chmod 0700 /home/${each.key}/.ssh/",
      "sudo cp /tmp/${each.key} /home/${each.key}/.ssh/authorized_keys",
      "sudo chown ${each.key}:${each.key} /home/${each.key}/.ssh/authorized_keys",
      "sudo chmod 0700 /home/${each.key}/.ssh/authorized_keys",
    ]
  }
}
