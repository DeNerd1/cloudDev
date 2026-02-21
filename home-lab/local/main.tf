terraform {
  required_providers {
    docker = {
        source = "kreuzwerker/docker"

    }
  }
}

provider "docker" {}

resource "docker_image" "app" {
  name = "nginx"
}
resource "docker_container" "app" {
    name = "nginx"
    image = docker_image.app.image_id
    ports {
      internal = 80
      external = 8181
    }

}

output "containter_net" {
   value = docker_container.app.network_data
}
output "logs" {
   value = docker_container.app.hostname
}