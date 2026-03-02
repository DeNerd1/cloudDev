terraform {
  required_providers {
    aws = {
        source = "hashicorp/aws"
        version = ">=5.0"
    }
  }
}

provider "aws" {
  region = "eu-north-1"
}

locals {
   proto ="tcp"
   cidr = ["0.0.0.0/0"]
}

resource "aws_security_group" "ec2" {
   name = "webacces-control"
   ingress {
       from_port = var.port
       to_port =  var.port
       protocol = local.proto
       cidr_blocks = local.cidr
       #cidr_blocks = ["0.0.0.0/0"]
    }
  
}

output "security_group_id" {
  value = aws_security_group.ec2.id
}
