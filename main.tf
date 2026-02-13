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

variable "access_port" {
  description = "port for the webapp"
  default = 9191
}

resource "aws_instance" "web0" {
   ami = "ami-073130f74f5ffb161"
   instance_type = "t3.micro"
   user_data = <<-EOF
             #!/bin/bash
             echo "<h1> Hello Wolrd </h1>" > index.html
             echo "<h3> Terafrom deployment </h3>" >> index.html
             nohup busybox httpd -f -p ${var.access_port} &
           EOF
   
   tags ={
     Name = "terrafom-vm"
   }


  # apply sec group to the instance 
  vpc_security_group_ids = [ aws_security_group.web0.id ]
}

# define a security group for the web access 
resource "aws_security_group" "web0" {
  
   name = "webaccess"
   ingress {
      from_port = var.access_port
      to_port =  var.access_port
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    
   }
  
}

# create a luch template or config to setup auto-scaling cluster 

resource "aws_launch_template" "web0" {
  image_id = "ami-073130f74f5ffb161"
  instance_type = "t3.micro"
     user_data = base64encode(<<-EOF
             #!/bin/bash
             echo "<h1> Hello Wolrd </h1>" > index.html
             echo "<h3> Terafrom deployment </h3>" >> index.html
             nohup busybox httpd -f -p ${var.access_port} &
          EOF 
     )
   tags ={
     Name = "terrafom-vm"
   }
 vpc_security_group_ids = [ aws_security_group.web0.id ]
 
   lifecycle {
     create_before_destroy = true

   }
}

resource "aws_autoscaling_group" "web0" {
  min_size = 2
  max_size = 5

  launch_template {
     id = aws_launch_template.web0.id
     version = "$Latest"    
  }
   tag {
      key = "Name"
      value = "auto-scale-terrfrom-app"
      propagate_at_launch = true
      
   }
   #availability_zones = [ aws_instance.web0.availability_zone ]

   # associate the load balancer 
   target_group_arns = [aws_lb_target_group.name.arn]
   vpc_zone_identifier = data.aws_subnets.default.ids 
}


# now let setup a load balacne to handle the autoscale groop
#get the network vpc

data "aws_vpc" "net" {
   default = true
}

#get subnet id with data source

data "aws_subnets" "default" {

  filter {
     name = "vpc-id"
     values = [data.aws_vpc.net.id]
  }

}
#deine a lb
resource "aws_lb" "web0" {
  name = "web-lb"
  subnets = data.aws_subnets.default.ids 
  security_groups = [ aws_security_group.lbsec.id ]
}
#define a listerner 
resource "aws_lb_listener" "web0" {
  load_balancer_arn = aws_lb.web0.arn
  port = 80
  protocol = "HTTP"
  #action when the above does not work
  default_action {
       type = "fixed-response"

       fixed_response {
         content_type = "text/plain"
         status_code = 404
         message_body = "404:page not found"
       }
  }

}

resource "aws_security_group" "lbsec" {
  name = "lbsec-group"
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  #allow all outbound
    egress {
       from_port = 0
       to_port = 0
       protocol = "-1"
       cidr_blocks = ["0.0.0.0/0"]
    }
}

# lb taget group
resource "aws_lb_target_group" "name" {
   name = "lbt-group"
   port = var.access_port
   protocol = "HTTP"
   vpc_id = data.aws_vpc.net.id
  
  health_check {
    path = "/"
    protocol = "HTTP"
    interval = 15
    matcher = "200"
    timeout = 3
   healthy_threshold = 2
   unhealthy_threshold = 2
  }
}

#listernar rule 
resource "aws_lb_listener_rule" "web0" {
   listener_arn = aws_lb_listener.web0.arn
   priority = 100

   action {
     type = "forward"
      target_group_arn = aws_lb_target_group.name.arn
   }

   condition {
    path_pattern {
      values = ["*"]
    }
   }
}


#output section-----------------------------------------------------------------
output "vm_info" {
  value = aws_instance.web0.public_ip
}

output "subnets" {
  value = data.aws_vpc.net.id
}

output "lb_ip" {
  value = aws_lb.web0.dns_name
}