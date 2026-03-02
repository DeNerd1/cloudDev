terraform {
  required_providers {
    aws ={
        source = "hashicorp/aws"
        version = ">=5.0"
    }
  }
}

provider "aws" {
  region = "eu-north-1"
}

data "aws_vpc" "net" {
    default = true
  
}

module "webacces" {
  source = "../frontend"
}
locals {
  image_id = "ami-073130f74f5ffb161"
  instance ="t3.micro"
}

resource "aws_instance" "ec2" {
  ami  = local.image_id
  instance_type = local.instance

  user_data = file("code.sh")
   
 vpc_security_group_ids = [module.webacces.sec_grp.id]
}

resource "aws_iam_user" "users" {
  count = length(var.user_names)
  name =  var.user_names["${count.index}"]

}


resource "aws_iam_group" "group" {
 for_each = toset(var.group_names)
 name = each.value

}



