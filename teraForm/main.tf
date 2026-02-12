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

provider "aws" {
  region = "eu-north-1"
}


resource "aws_s3_bucket" "demo_s3bk" {
   bucket = "demo1-web-s3-bucket"
}


resource "aws_instance" "web01-server" {
  instance_type = "t3.micro"
  ami = "ami-00189892024f9f6fe"
  tags = {
    "Name" ="Teramform-server" 
  }
  

}

resource "local_file" "hello" {
    content = "Hello world"
    filename = "hello.txt"
  
}