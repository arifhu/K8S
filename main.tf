provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "minikube"
}

resource "kubernetes_persistent_volume" "task-pv-volume" {
  metadata {
    name = "task-pv-volume"
  }
  spec {
    storage_class_name = "manual"
    capacity = {
      storage = "10Gi"
    }
    access_modes = ["ReadWriteOnce"]
    persistent_volume_source {
      #vsphere_volume {
      #  volume_path = "/mnt/data"
      #}
      host_path {
          path = "/mnt/data"
      }
    }
  }
}

resource "kubernetes_persistent_volume_claim" "task-pv-claim" {
  metadata {
    name = "task-pv-claim"
  }
  spec {
    storage_class_name = "manual"
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "3Gi"
      }
    }
    volume_name = "${kubernetes_persistent_volume.task-pv-volume.metadata.0.name}"
  }
}


resource "kubernetes_deployment" "star-wars-deployment" {
  metadata {
    name = "star-wars-deployment"
    labels = {
      test = "star-wars"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        test = "star-wars"
      }
    }

    template {
      metadata {
        labels = {
          test = "star-wars"
        }
      }

      spec {
        container {
          image = "starwars-node"
          name  = "star-wars"
          port {
            container_port = 3000
          }
          image_pull_policy = "Never"
          resources {
            limits = {
              cpu    = "0.5"
              memory = "512Mi"
            }
            requests = {
              cpu    = "250m"
              memory = "50Mi"
            }
          }


        }
      }
    }
  }
}


resource "kubernetes_service" "sw-service" {
  metadata {
    name = "sw-service"
  }
  spec {
    selector = {
      app = "star-wars"
    }
    session_affinity = "ClientIP"
    port {
      port        = 3000
      target_port = 31000
      node_port = "31000"
    }

    type = "LoadBalancer"
  }
}
