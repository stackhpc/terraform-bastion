data "openstack_networking_network_v2" "bastion" {
  name = var.network
}

resource "openstack_networking_port_v2" "bastion" {
  name           = var.name
  network_id     = data.openstack_networking_network_v2.bastion.id
  admin_state_up = "true"
}

resource "openstack_compute_floatingip_associate_v2" "bastion" {
  floating_ip = var.fip
  instance_id = openstack_compute_instance_v2.bastion.id
}

resource "openstack_compute_keypair_v2" "bastion" {
  name = var.name
}

resource "openstack_compute_instance_v2" "bastion" {
  name            = var.name
  image_id        = var.image
  flavor_id       = var.flavor
  key_pair        = var.name
  config_drive    = "true"
  security_groups = ["default"]

  network {
    port = openstack_networking_port_v2.bastion.id
  }
}

resource "null_resource" "users" {
  triggers = {
    host            = var.fip
    user            = var.user
    private_key     = openstack_compute_keypair_v2.bastion.private_key
    instance        = openstack_compute_instance_v2.bastion.id
    authorized_keys = file("authorized_keys/${each.key}")
  }

  for_each = fileset("${path.module}/authorized_keys", "*")

  connection {
    user        = self.triggers.user
    host        = self.triggers.host
    private_key = self.triggers.private_key
  }

  provisioner "file" {
    content     = self.triggers.authorized_keys
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

  provisioner "remote-exec" {
    when       = destroy
    on_failure = continue
    inline     = ["sudo userdel -r ${each.key}"]
  }
}
