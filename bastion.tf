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
  name       = var.name
  public_key = var.public_key
}

resource "openstack_compute_instance_v2" "bastion" {
  name            = var.name
  image_id        = var.image
  flavor_id       = var.flavor
  key_pair        = openstack_compute_keypair_v2.bastion.id
  config_drive    = "true"
  security_groups = ["default"]

  network {
    port = openstack_networking_port_v2.bastion.id
  }
}

locals {
  users = fileset("${path.module}/authorized_keys", "*")
}

resource "null_resource" "users" {
  for_each = local.users

  triggers = {
    host            = var.fip
    user            = var.user
    private_key     = var.private_key
    instance        = openstack_compute_instance_v2.bastion.id
    authorized_keys = file("authorized_keys/${each.key}")
  }

  connection {
    user        = self.triggers.user
    host        = self.triggers.host
    private_key = self.triggers.private_key
  }

  provisioner "file" {
    content     = self.triggers.authorized_keys
    destination = "/tmp/${each.key}.pub"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo useradd -m -s /bin/bash ${each.key}",
      "sudo mkdir -p /home/${each.key}/.ssh/",
      "sudo chown ${each.key}:${each.key} /home/${each.key}/.ssh/",
      "sudo chmod 0700 /home/${each.key}/.ssh/",
      "sudo mv /tmp/${each.key}.pub /home/${each.key}/.ssh/authorized_keys",
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

resource "null_resource" "sudoers" {
  for_each = toset(var.sudoers)

  triggers = {
    host        = var.fip
    user        = var.user
    instance    = openstack_compute_instance_v2.bastion.id
    private_key = var.private_key
  }

  connection {
    user        = self.triggers.user
    host        = self.triggers.host
    private_key = self.triggers.private_key
  }

  provisioner "file" {
    content     = "${each.key} ALL=(ALL) NOPASSWD: ALL"
    destination = "/tmp/${each.key}"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mv /tmp/${each.key} /etc/sudoers.d/${each.key}",
    ]
  }

  provisioner "remote-exec" {
    when       = destroy
    on_failure = continue
    inline     = ["sudo rm /etc/sudoers.d/${each.key}"]
  }
}

resource "null_resource" "unattended-upgrades" {
  triggers = {
    host        = var.fip
    user        = var.user
    instance    = openstack_compute_instance_v2.bastion.id
    private_key = var.private_key
  }

  connection {
    user        = self.triggers.user
    host        = self.triggers.host
    private_key = self.triggers.private_key
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'Unattended-Upgrade::Automatic-Reboot \"true\";' | sudo tee -a /etc/apt/apt.conf.d/50unattended-upgrades",
      "echo 'Unattended-Upgrade::Automatic-Reboot-Time \"02:00\";' | sudo tee -a /etc/apt/apt.conf.d/50unattended-upgrades",
    ]
  }
}
