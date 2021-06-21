variable "fip" {
  type = string
}

variable "name" {
  type = string
}

variable "network" {
  type = string
}

variable "image" {
  type = string
}

variable "flavor" {
  type = string
}

variable "user" {
  default = "ubuntu"
  type    = string
}

variable "public_key" {
  type = string
}

variable "private_key" {
  sensitive = true
  type      = string
}

variable "sudoers" {
  default = []
  type    = list(string)
}

variable "software" {
  default = ["mosh"]
  type    = list(string)
}


variable "ssh_host_ecdsa_key" {
  sensitive = true
}

variable "ssh_host_rsa_key" {
  sensitive = true
}

variable "ssh_host_ed25519_key" {
  sensitive = true
}
