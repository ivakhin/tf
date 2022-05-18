variable "namespace" {}

variable "name" {
  default     = "mongo"
  description = <<EOT
Base name for all kubernetes resource names and labels. Try to make it unique.
Default value is only suitable for local single deployment.
A good template for non-local deployments is [PROJECT_NAME][ENVIRONMENT][DATA_CENTER_NAME][GIT_BRANCH_SLUG].
EOT
}

variable "storageSize" {
  default = "10Gi"
}

variable "storageClass" {
  default = "standard"
}

variable "replicas" {
  default = 1
  validation {
    condition     = var.replicas > 0
    error_message = "Couldn't make replica set without replicas."
  }
}

variable "image" {
  default     = "percona/percona-server-mongodb:5.0"
  description = "The module has been tested with mongo:4.0 and newer."
}

variable "port" {
  default = 27017
}

variable "replicaSet" {
  default = "rs0"
}

variable "annotations" {
  type    = map(string)
  default = {}
}

variable "labels" {
  type = map(string)
}