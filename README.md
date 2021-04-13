vglab-bastion
-------------

This repo contains Terraform script for provisioning `vglab-bastion` and
managing users on the instance.

To add a new user, create a new file under `authorized_keys/<user>` with SSH
public key for the given user then:

    terraform init  # first use only
    terraform apply

To remove a user, delete file `authorized_keys/<user>` and apply.

Maintainer:
- bharat@stackhpc.com
