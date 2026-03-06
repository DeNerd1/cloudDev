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


data "aws_vpc" "default" {
   default = true
}

data "aws_subnets" "default" {
    filter {
        name = "vpc-id"
        values = [ data.aws_vpc.default.id ]
        }

    filter {
        name = "availability-zone"
        values = ["eu-north-1a","eu-north-1c"]
    }


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
## luch template
resource "aws_launch_template" "lt-config" {
  image_id = "ami-073130f74f5ffb161"
  instance_type = "t3.micro"

    user_data = base64encode( <<-EOF
           #!/bin/bash
           echo "hello world" >index.html
           nohup busybox httpd -f -p {var.server_port} &
          EOF
    )
  vpc_security_group_ids = [ aws_security_group.webAcess.id ]
  # security_groups = [aws_security_group.webAcess.id]
  

   lifecycle {
     create_before_destroy = true
     
   }
}
# autocate setup
resource "aws_autoscaling_group" "lt" {
    #launch_configuration = aws_launch_configuration.lconfig.name
    launch_template {
      id = aws_launch_template.lt-config.id
      version = "$Latest"
    }
    target_group_arns = [aws_lb_target_group.lbtg.arn]
    health_check_type = "ELB"
    vpc_zone_identifier = [data.aws_subnets.default.id]
    min_size = 2
    max_size = 5
    tag {
      key = "Name"
      value = "teraramform-autoscale"
      propagate_at_launch = true
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

# setup a load balancer 
resource "aws_lb" "appLB" {
  name = "terraform-lb"
  load_balancer_type = "application"
  subnets = data.aws_subnets.default.ids 

  security_groups = [aws_security_group.alb.id]
}

resource "aws_lb_listener" "http" {
    load_balancer_arn = aws_lb.appLB.arn
    port = 80
    protocol = "HTTP"
    
    default_action {
      type = "fixed-response"

      fixed_response {
        content_type = "text/plain"
        message_body = "404:page not found"
        status_code = 404
      }
    }
}

resource "aws_security_group" "alb" {
    name = "lbsec-group"
  ingress {
      from_port = 80
      to_port = 80
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }

  # Allow all outbound requests
  egress {
     from_port = 0
     to_port = 0
     protocol = "-1"
     cidr_blocks = ["0.0.0.0/0"]
  }
    
}

resource "aws_lb_target_group" "lbtg" {
    name = "lbtg-group"
    port = var.server_port
    protocol = "HTTP"
    vpc_id = data.aws_vpc.default.id
    
    health_check {
      path = "/"
      protocol = "HTTP"
      matcher = "200"
      interval = 15
      timeout = 3
      healthy_threshold = 2
      unhealthy_threshold = 2
    }
}


resource "aws_lb_listener_rule" "lbrule" {
   listener_arn = aws_lb_listener.http.arn
   priority = 100
  
  action {
    type = "forward"
     target_group_arn = aws_lb_target_group.lbtg.arn
  }
  
  condition {
     path_pattern {
       values = ["*"]
     }
  }
}


output "vpc_info" {
   value = data.aws_vpc.default.id
}


output "public_ip" {
  description = "Get public IP"
  value = aws_instance.web01-server.public_ip

}

output "alb_dns" {
  description = "get the load balacner dns "
  value = aws_lb.appLB.dns_name
  
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