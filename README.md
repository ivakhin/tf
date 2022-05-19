# Terraform modules

---
## Kubernetes
### Mongodb replicaset

Mongodb replica set deployment without authorization for local and stage environments.

Example:
```terraform
module "mongo_full" {
  source       = "github.com/ivakhin/tf//kubernetes/mongors"
  name         = "someapp-local-main-mongo"
  namespace    = "someapp"
  storageClass = "standard"
  storageSize  = "20Gi"
  annotations  = {
    "project/git"   = "https://github.com/ivakhin/someapp"
    "project/owner" = "v.ivakhin@gmail.com"
  }
  labels = {
    "env"  = "local"
    "name" = "someapp-local-main"
  }
  replicas   = 3
  image      = "mongo:5.0"
  port       = 27017
  replicaSet = "rs1"
}

module "mongo_quick" {
  source       = "github.com/ivakhin/tf//kubernetes/mongors"
  name         = "mongo"
  namespace    = "someapp"
  labels = {
    "name" = "mongo"
  }
}

module "app" {
  mongoDsn   = module.mongo_quick.dsn
  mongoHosts = module.mongo_quick.hosts
}
```
---