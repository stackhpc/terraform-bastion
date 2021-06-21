data "openstack_networking_network_v2" "bastion" {
  name = var.network
}

resource "openstack_networking_port_v2" "bastion" {
  name           = var.name
  network_id     = data.openstack_networking_network_v2.bastion.id
  admin_state_up = "true"
}

resource "openstack_networking_floatingip_associate_v2" "bastion" {
  floating_ip = var.fip
  port_id     = openstack_networking_port_v2.bastion.id
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
    user            = var.user
    private_key     = var.private_key
    host            = openstack_networking_floatingip_associate_v2.bastion.floating_ip
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
    user        = var.user
    private_key = var.private_key
    host        = openstack_networking_floatingip_associate_v2.bastion.floating_ip
    instance    = openstack_compute_instance_v2.bastion.id
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
    user        = var.user
    private_key = var.private_key
    host        = openstack_networking_floatingip_associate_v2.bastion.floating_ip
    instance    = openstack_compute_instance_v2.bastion.id
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

resource "null_resource" "software" {
  for_each = toset(var.software)

  triggers = {
    user        = var.user
    private_key = var.private_key
    host        = openstack_networking_floatingip_associate_v2.bastion.floating_ip
    instance    = openstack_compute_instance_v2.bastion.id
  }

  connection {
    user        = self.triggers.user
    host        = self.triggers.host
    private_key = self.triggers.private_key
  }

  provisioner "remote-exec" {
    inline = ["sudo apt install -y ${each.key}"]
  }

  provisioner "remote-exec" {
    when       = destroy
    on_failure = continue
    inline     = ["sudo apt remove -y ${each.key}"]
  }
}

resource "null_resource" "host-key" {
  triggers = {
    user        = var.user
    private_key = var.private_key
    host        = openstack_networking_floatingip_associate_v2.bastion.floating_ip
    instance    = openstack_compute_instance_v2.bastion.id
    host_keys   = join("\n", [var.ssh_host_rsa_key, var.ssh_host_ecdsa_key, var.ssh_host_ed25519_key])
  }

  connection {
    user        = self.triggers.user
    host        = self.triggers.host
    private_key = self.triggers.private_key
  }

  provisioner "file" {
    content     = var.ssh_host_rsa_key
    destination = "/tmp/ssh_host_rsa_key"
  }

  provisioner "file" {
    content     = var.ssh_host_ecdsa_key
    destination = "/tmp/ssh_host_ecdsa_key"
  }

  provisioner "file" {
    content     = var.ssh_host_ed25519_key
    destination = "/tmp/ssh_host_ed25519_key"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mv /tmp/ssh_host_*_key /etc/ssh/",
      "sudo chown root:root /etc/ssh/ssh_host_*_key",
      "sudo chmod 600 /etc/ssh/ssh_host_*_key",
      "sudo rm /etc/ssh/ssh_host_*_key.pub || true",
    ]
  }
}
