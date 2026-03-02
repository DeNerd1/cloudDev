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


module "webacess" {
  source = "../webacess"
}

resource "aws_instance" "ec2" {
  instance_type = "t3.micro"
  ami           = var.iam_id
  user_data     = file("code.sh")

  vpc_security_group_ids = [module.webacess.security_group_id]

  tags = {
    Name = "web01"

    
  }
}

