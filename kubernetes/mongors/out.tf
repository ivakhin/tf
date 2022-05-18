output "hosts" {
  value = local.hosts
}

output "dsn" {
  value = "mongodb://${join(",", local.hosts)}/${var.replicaSet}"
}