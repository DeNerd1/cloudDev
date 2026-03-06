terraform {
  required_providers {
    aws ={
        source = "hashicorp/aws"
        version = ">=5.1"
    }
  }

}

provider "aws" {
  region = "eu-north-1"
}

resource "aws_instance" "web0" {
   ami = "ami-073130f74f5ffb161"
   instance_type = "t3.micro"

   user_data = file("code.sh")

   tags = {
     Name: "webapp"
   }
  vpc_security_group_ids = [ aws_security_group.websec.id]
}


resource "aws_security_group" "websec" {
     name = "websec-group"
     ingress {
        from_port = 9191
        to_port = 9191
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
     }
}



