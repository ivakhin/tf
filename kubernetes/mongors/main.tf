locals {
  datadir = { name = "data", path = "/data/db" }
  ping    = ["mongo", "--eval", "db.adminCommand('ping')"]

  initCmd = format("rs.initiate(%s)", jsonencode({
    _id     = var.replicaSet
    members = local.members
  }))

  hosts = [
    for i in range(var.replicas) : format("${var.name}-%d.${kubernetes_service.service.metadata.0.name}:${var.port}", i)
  ]

  members = [
    for i, host in local.hosts : {
      _id  = i,
      host = host
    }
  ]
}

resource "kubernetes_stateful_set" "mongodb" {
  metadata {
    name      = var.name
    namespace = var.namespace
    labels = {
      for key, value in var.labels : key => value
    }
    annotations = {
      for key, value in var.annotations : key => value
    }
  }

  timeouts {
    create = "2m"
    update = "1m"
    delete = "1m"
  }

  spec {
    service_name = kubernetes_service.service.metadata.0.name
    replicas     = var.replicas

    selector {
      match_labels = {
        for key, value in var.labels : key => value
      }
    }

    template {
      metadata {
        labels = {
          for key, value in var.labels : key => value
        }
        annotations = {
          for key, value in var.annotations : key => value
        }
      }

      spec {
        volume {
          name = local.datadir.name
        }

        termination_grace_period_seconds = 10

        container {
          name  = var.name
          image = var.image
          args = [
            "--dbpath", local.datadir.path,
            "--replSet", var.replicaSet,
            "--port", var.port,
            "--bind_ip_all",
            "--noauth"
          ]

          port {
            container_port = var.port
          }

          volume_mount {
            name       = local.datadir.name
            mount_path = local.datadir.path
          }

          startup_probe {
            exec {
              command = local.ping
            }

            initial_delay_seconds = 5
            timeout_seconds       = 5
            period_seconds        = 5
            success_threshold     = 1
            failure_threshold     = 5
          }

          readiness_probe {
            exec {
              command = local.ping
            }

            initial_delay_seconds = 5
            timeout_seconds       = 1
            period_seconds        = 10
            success_threshold     = 1
            failure_threshold     = 3
          }

          image_pull_policy = "IfNotPresent"
        }

        security_context {
          run_as_non_root = true
          run_as_user     = 1001
        }
      }
    }

    volume_claim_template {
      metadata {
        name      = local.datadir.name
        namespace = var.namespace
        labels = {
          for key, value in var.labels : key => value
        }
        annotations = {
          for key, value in var.annotations : key => value
        }
      }

      spec {
        access_modes       = ["ReadWriteOnce"]
        storage_class_name = var.storageClass

        resources {
          requests = {
            storage = var.storageSize
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "service" {
  metadata {
    name      = var.name
    namespace = var.namespace
    labels = {
      for key, value in var.labels : key => value
    }
    annotations = {
      for key, value in var.annotations : key => value
    }
  }

  spec {
    port {
      name        = var.name
      port        = var.port
      target_port = var.port
    }

    selector = {
      for key, value in var.labels : key => value
    }

    cluster_ip = "None"
  }
}

resource "kubernetes_job" "init" {
  metadata {
    name      = var.name
    namespace = var.namespace
    labels = {
      for key, value in var.labels : key => value
    }
    annotations = {
      for key, value in var.annotations : key => value
    }
  }

  depends_on = [kubernetes_stateful_set.mongodb]

  timeouts {
    create = "20s"
    update = "20s"
    delete = "20s"
  }

  spec {
    ttl_seconds_after_finished = 3600

    template {
      metadata {
        labels = {
          for key, value in var.labels : key => value
        }
        annotations = {
          for key, value in var.annotations : key => value
        }
      }

      spec {
        container {
          name    = "${var.name}-init"
          image   = var.image
          command = ["mongo"]
          args = [
            "--host", "${var.name}-0.${kubernetes_service.service.metadata.0.name}",
            "--port", var.port,
            "--eval", local.initCmd
          ]
        }

        restart_policy = "OnFailure"
      }
    }
  }
}