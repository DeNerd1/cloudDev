terraform {
  required_providers {
   aws ={
    source = "hashicorp/aws"
    version = ">=5.0"
   }

    google = {
         source = "hashicorp/google"
    }
    local ={
        source = "hashicorp/local"
        version = ">=2.0"

    }
  }
}
resource "local_file" "hello" {
    content = "Hello world"
    filename = "hello.txt"
  
}

provider "aws" {
  region = "eu-north-1"
}


resource "aws_s3_bucket" "demo_s3bk" {
   bucket = "demo1-web-s3-bucket"
}


resource "aws_instance" "web01-server" {
  instance_type = "t3.micro"
  ami = "ami-073130f74f5ffb161"
 
  user_data = <<-EOF
           #!/bin/bash
           echo "hello world" >index.html
           nohup busybox httpd -f -p {var.server_port} &
          EOF

    vpc_security_group_ids = [ aws_security_group.webAcess.id ]

  tags = {
    "Name" ="Teramform-server" 
  }

}

resource "aws_security_group" "webAcess" {
    name = "terraform-web-access"
    ingress  {
      from_port = var.server_port 
      to_port = var.server_port
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]

    }
}


variable "server_port" {
  description = "web server port"
  type = number
  default = 8080
  
}

output "public_ip" {
  description = "Get public IP"
  value = aws_instance.web01-server.public_ip

}

output "bucket_name" {
  description = "Getting bucket policy"
  value = aws_s3_bucket.demo_s3bk.bucket
  
}

variable "number_example"  {
  description = "An example of declaring a number "
  type = number
  default = 100

}

variable "list_example" {
  description = "List of characters"
  type = list
  default = ["a","b","c"]
}


variable "string_exmaple" {
   description = "Some stings "
   type = map(string)
   default = {
     "k1" = "hello"
      "k2" ="how are you"
   }
  
}