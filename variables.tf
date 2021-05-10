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
  default = "34a622a7-703e-4d43-b116-6fe92f04de14" # Ubuntu-20.04
}

variable "flavor" {
  default = "2d838268-d90e-4db0-8023-7a3638805313" # general.v1.tiny
}

variable "key_pair" {
  default = "bharat-mac"
}

variable "user" {
  default = "ubuntu"
}

variable "cloud" {
  default = "vglab"
}
