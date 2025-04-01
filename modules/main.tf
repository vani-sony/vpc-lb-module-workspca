provider "aws" {
    region = var.region
}

resource "aws_vpc" "vpc1" {
 cidr_block = var.vpccidr
 tags = {
   Name = "vpc1"
 }
} 
resource "aws_subnet" "pubsub1" {
    vpc_id = aws_vpc.vpc1.id
    cidr_block = var.publicsubn1
    availability_zone = "ap-south-1a"
    map_public_ip_on_launch = true
    tags = {
      Name = "pubsub1"
    }
}
resource "aws_subnet" "pubsub2" {
    vpc_id = aws_vpc.vpc1.id
    cidr_block = var.publicsubn2
    availability_zone = "ap-south-1b"
    tags = {
      Name = "pubsub2"
    }
    map_public_ip_on_launch = true
}

resource "aws_subnet" "prvsub1" {
    vpc_id = aws_vpc.vpc1.id
    cidr_block = var.privatesubn1
    availability_zone = "ap-south-1a"
    tags = {
      Name = "prvsub1"
    }
}
resource "aws_subnet" "prvsub2" {
    vpc_id = aws_vpc.vpc1.id
    cidr_block = var.privatesubn2
    availability_zone = "ap-south-1b"
    tags = {
      Name = "prvsub2"
    }
    map_public_ip_on_launch = false
}


resource "aws_internet_gateway" "igw1" {
    vpc_id = aws_vpc.vpc1.id
    tags = {
      Name = "igw1" 
    }
    depends_on = [ aws_vpc.vpc1 ]
}
resource "aws_eip" "eip1" {
  domain                    = "vpc"
  tags = {
    Name = "eip1"
  }
}

resource "aws_nat_gateway" "ngw1" {
  allocation_id = aws_eip.eip1.id
  subnet_id     = aws_subnet.pubsub1.id
  depends_on = [ aws_eip.eip1 ]

  tags = {
    Name = "ngw1"
  }
}

resource "aws_route_table" "publicroute" {
  vpc_id = aws_vpc.vpc1.id
  route {
    cidr_block = var.publiroute
    gateway_id = aws_internet_gateway.igw1.id
  }
  tags = {
    Name = "publicroute"
  }
}
resource "aws_route_table_association" "public-subnet-association1" {
  subnet_id      = aws_subnet.pubsub1.id 
  route_table_id = aws_route_table.publicroute.id
}
resource "aws_route_table_association" "public-subnet-association2" {
  subnet_id      = aws_subnet.pubsub2.id
  route_table_id = aws_route_table.publicroute.id
}




resource "aws_route_table" "privatenat" {
 vpc_id = aws_vpc.vpc1.id
   route {
    cidr_block = var.privroute
    gateway_id = aws_nat_gateway.ngw1.id
  }
  tags = {
    Name = "privatecroute"
  }
}
resource "aws_route_table_association" "private-subnet-association1" {
  subnet_id      = aws_subnet.prvsub1.id
  route_table_id = aws_route_table.privatenat.id
}
resource "aws_route_table_association" "private-subnet-association2" {
  subnet_id      = aws_subnet.prvsub2.id
  route_table_id = aws_route_table.privatenat.id
}
resource "aws_security_group" "sg1" {
  name        = "sgforall"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.vpc1.id

  ingress {
    description = "TLS from VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "sg1"
  }
}
resource "aws_lb" "alb1" {
  name               = "appload1b"
  load_balancer_type = var.lbtype
  internal           = false
  security_groups    = [aws_security_group.sg1.id]
  subnets = [aws_subnet.pubsub1.id, aws_subnet.pubsub2.id]
  depends_on = [aws_internet_gateway.igw1]
}
resource "aws_lb_target_group" "tg1" {
  name        = "tgv"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.vpc1.id
}
resource "aws_lb_listener" "lblistener" {
  load_balancer_arn = aws_lb.alb1.arn
  port              = "80"
  protocol          = "HTTP"
 

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg1.arn
      }
      tags = {
        Name = "listener"
      }
}



resource "aws_launch_template" "lt1" {
    name = "launch1"
    description = "launch template"
    image_id = var.lt_amiid
    instance_type = var.lt_type
    key_name = "vaninew"
    network_interfaces {
      security_groups = [aws_security_group.sg1.id]
      associate_public_ip_address = false
    
    }
  user_data = base64encode(<<-EOF
    #!/bin/bash
    sudo yum install git -y
    sudo yum install httpd -y
    systemctl enable httpd
    systemctl start httpd
    echo 'hello' > /var/www/html/index.html
  EOF
  )
}

resource "aws_autoscaling_group" "aslb" {
  name                      = "autoscal"
  max_size                  = 5
  min_size                  = 2
  desired_capacity          = 2
  vpc_zone_identifier = [aws_subnet.prvsub1.id, aws_subnet.prvsub2.id]
  target_group_arns = [aws_lb_target_group.tg1.arn]
  launch_template {
    id = aws_launch_template.lt1.id
    
  }   
  health_check_grace_period = 100
  health_check_type         = "EC2"
  force_delete              = true

}
