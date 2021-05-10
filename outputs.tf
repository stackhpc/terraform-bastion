output "users" {
  value = keys(null_resource.users)
}

output "fip" {
  value = var.fip
}

data "external" "env" { program = ["jq", "-n", "env"] }


output "test" {
  value = "${data.external.env.result}"
}
