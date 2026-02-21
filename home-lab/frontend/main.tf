provider "aws" {
  region = "eu-north-1"
}

resource "aws_security_group" "acces" {
    name = "webacces-sec"
    ingress {
      from_port = var.port
      to_port = var.port
      protocol = var.proto
      cidr_blocks = var.network

    }
    
}

output "sec_grp" {
   value = aws_security_group.acces
   
}