variable "fip" {
  default = "185.45.78.150"
}

variable "name" {
  default = "vglab-bastion"
}

variable "network" {
  default = "ovn-network"
}

variable "image" {
  default = "Ubuntu-20.04"
}

variable "flavor" {
  default = "general.v1.medium"
}

variable "key_pair" {
  default = "bharat-mac"
}

variable "user" {
  default = "ubuntu"
}
