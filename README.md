bastion-terraform
=================

This repo contains Terraform script for provisioning a bastion host and
managing users and their SSH keys on the instance.

Configuration
-------------

On the repository, ensure the following variables are set:

    TF_API_TOKEN # obtained from <https://app.terraform.io/app/settings/tokens>
    TF_WORKSPACE # which matches the prefix bastion-

On the remote terraform backend, ensure that the following variables are defined:

    OS_APPLICATION_CREDENTIAL_SECRET
    OS_APPLICATION_CREDENTIAL_ID
    OS_AUTH_URL

Administration
--------------

To add a new user, create a new file under `authorized_keys/<user>` with the
SSH public key for the given user then create a pull request.

To remove a user, delete `authorized_keys/<user>` and create a pull request.

If you are running this on your local machine:

    terraform login # first time only
    terraform init  # first time only
    terraform apply

Maintainers
----------
See [CODEOWNERS](./.github/CODEOWNERS).
