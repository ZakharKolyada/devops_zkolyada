provider "local" {
  # Local provider configuration
}

resource "null_resource" "minikube_start" {
  provisioner "local-exec" {
    command = <<EOT
      minikube start --driver=docker
    EOT
  }
}

output "minikube_ip" {
  value = "Minikube started"
}

resource "null_resource" "deploy_wordpress" {
  depends_on = [null_resource.minikube_start]

  provisioner "local-exec" {
    command = <<EOT
      helm repo add bitnami https://charts.bitnami.com/bitnami
      helm repo update
      helm install my-wordpress bitnami/wordpress --set service.type=NodePort
    EOT
  }
}

