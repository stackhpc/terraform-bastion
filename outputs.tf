output "users" {
  value = keys(null_resource.users)
}

output "fip" {
  value = var.fip
}
