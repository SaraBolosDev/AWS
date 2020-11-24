# AWS assignment
#Author: Sara bolos
#prior running the code please read the README file in the repo :

#Define aws cloud for terraform
    provider "aws" {
    region = var.aws_region
    access_key    = var.aws_access_key
    secret_key    = var.aws_secret_key

}

# 1. Create a vpc
resource "aws_vpc" "prod-vpc" {
   cidr_block = var.vpc_cidr
    enable_dns_hostnames = true
     tags = {
         Name = "VPC"
     }
}

# 2. create an internet gateway, is the way out to the internet for public resources.
# If a VPC does not have an Internet Gateway, then the resources in the VPC cannot be accessed
# from the Internet (unless the traffic flows via a corporate network and VPN/Direct Connect)
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.prod-vpc.id

}

# 3. create a route table
#To communicate between the addresses of the machines, we need to route, 
#and routing tables tell the system how the packets should move around and where to put the next packet. 
#The routing table contains routes that contain the destination or target mapping.
# Destination here refers to the destination of CIDR, where you want traffic from your subnet to go. 
resource "aws_route_table" "prod-route-table" {
  vpc_id = aws_vpc.prod-vpc.id

  route {
    cidr_block = var.cidr_blocks
    gateway_id = aws_internet_gateway.gw.id
  }

  route {
    ipv6_cidr_block        = "::/0"
    gateway_id  = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "Prod"
  }
}

#4. creating two subnets
resource "aws_subnet" "subnet-1" {
  vpc_id     = aws_vpc.prod-vpc.id
  cidr_block = var.public_subnet_cidr1
  availability_zone = var.aws_region1

  tags = {
    Name = "prod-subnet1"
  }
}
resource "aws_subnet" "subnet-2" {
  vpc_id     = aws_vpc.prod-vpc.id
  cidr_block = var.public_subnet_cidr2
  availability_zone = var.aws_region2

  tags = {
    Name = "prod-subnet2"
  }
}

#5. Aassociate the subnets with the route table
resource "aws_route_table_association" "a" {
   subnet_id     = aws_subnet.subnet-1.id
  route_table_id = aws_route_table.prod-route-table.id
}
resource "aws_route_table_association" "b" {
   subnet_id     = aws_subnet.subnet-2.id
  route_table_id = aws_route_table.prod-route-table.id
}

#6. create a security group for both instances
resource "aws_security_group" "allow_web" {
  name        = "allow_web_traffic"
  description = "Allow web inbound traffic"
  vpc_id      = aws_vpc.prod-vpc.id


  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.cidr_blocks]
  }
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.cidr_blocks]
  }
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.cidr_blocks]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.cidr_blocks]
  }

  tags = {
    Name = "allow_web"
  }
}

#7. create a network interface with an ip in the subnet that was created in step 4
resource "aws_network_interface" "web-server-nic1" {
  subnet_id       = aws_subnet.subnet-1.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.allow_web.id]

} 
resource "aws_network_interface" "web-server-nic2" {
  subnet_id       = aws_subnet.subnet-2.id
  private_ips     = ["10.0.2.50"]
  security_groups = [aws_security_group.allow_web.id]

} 
#8. Assign an elastic ip to the network interface created in step 7
resource "aws_eip" "one" {
  vpc                       = true
  network_interface         = aws_network_interface.web-server-nic1.id
  associate_with_private_ip = "10.0.1.50"
  depends_on = [aws_internet_gateway.gw]
}
resource "aws_eip" "two" {
  vpc                       = true
  network_interface         = aws_network_interface.web-server-nic2.id
  associate_with_private_ip = "10.0.2.50"
  depends_on = [aws_internet_gateway.gw]
}

#9. create first instance
resource "aws_instance" "web-server-instance1" {
  ami    = var.ami
  instance_type = "t2.micro"
  key_name = "" #your key name goes here

    network_interface {
        device_index = 0
        network_interface_id = aws_network_interface.web-server-nic1.id
    }

       user_data = <<-EOF
                 #!/bin/bash
                 sudo apt update -y
                 sudo apt install apache2 -y
                 sudo systemctl start apache2
                 sudo apt install mysql-client-core-8.0  
                 sudo bash -c 'echo first web server > /var/www/html/index.html'
                 EOF
   tags = {
    Name = "web-server1"
   }
}

resource "aws_instance" "web-server-instance2" {
  ami    = var.ami
  instance_type = "t2.micro"
  key_name = "main-key"

    network_interface {
        device_index = 0
        network_interface_id = aws_network_interface.web-server-nic2.id
    }

       user_data = <<-EOF
                 #!/bin/bash
                 sudo apt update -y
                 sudo apt install apache2 -y
                 sudo systemctl start apache2
                 sudo apt install mysql-client-core-8.0  
                 sudo bash -c 'echo second web server > /var/www/html/index.html'
                 EOF
   tags = {
    Name = "web-server2"
   }
}

# 10. create the database group
resource "aws_db_parameter_group" "db-group" {
  name   = "rds-pg"
  family = "mysql8.0"

  parameter {
    name  = "character_set_server"
    value = "utf8"
  }

  parameter {
    name  = "character_set_client"
    value = "utf8"
  }
}

#11.create private subnets for DB

resource "aws_subnet" "private-1" {
    vpc_id = aws_vpc.prod-vpc.id
    cidr_block = var.private_subnet_cidr1
    availability_zone = var.aws_region1
    map_public_ip_on_launch="false"

     tags = {
         Name = "Private Subnet1"
     }
}
resource "aws_subnet" "private-2" {
    vpc_id = aws_vpc.prod-vpc.id
    cidr_block = var.private_subnet_cidr2
    availability_zone = var.aws_region2
    map_public_ip_on_launch="false"

     tags = {
        Name = "Private Subnet2"
     }
}

#12. use the private subnets in step 11 for the db subnet group
resource "aws_db_subnet_group" "db-subnet" {
  name       = "main"
  subnet_ids = [ aws_subnet.private-1.id , aws_subnet.private-2.id ]

  tags = {
    Name = "My DB subnet group"
  }
}

#13. create the secuiry group for db
resource "aws_security_group" "rds-sg" {
  name        = "rds-security-group"
  description = "allow inbound access to the database"
  vpc_id      = aws_vpc.prod-vpc.id

// allows traffic from the SG itself
    ingress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        self = true
    }

    // allow traffic for TCP 3306
    ingress {
        from_port = 3306
        to_port = 3306
        protocol = "tcp"
        security_groups = [aws_security_group.allow_web.id]
    }

    // outbound internet access
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = [var.cidr_blocks]
    }

}

# 14. creating the db instance
resource "aws_db_instance" "db-instance" {
  allocated_storage    = 100
  storage_type         = "gp2"
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = "db.t2.micro"
  identifier           = "mydb"
  name                 = "mydb"
  username             = "root"
  password             = "complex1891"
  parameter_group_name = aws_db_parameter_group.db-group.id
  db_subnet_group_name = aws_db_subnet_group.db-subnet.id
  vpc_security_group_ids = [ aws_security_group.rds-sg.id ]
  publicly_accessible  = false
  skip_final_snapshot  = true
  multi_az             = false
}


# 15. Creating loadBalancer for instance
resource "aws_elb" "elb" {
  name = "ELB-WEB"
  security_groups = [aws_security_group.allow_web.id]
  subnets= [aws_subnet.subnet-1.id,aws_subnet.subnet-2.id]
  instances= [aws_instance.web-server-instance1.id, aws_instance.web-server-instance2.id]
  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 3
    interval = 30
    target = "HTTP:80/"
  }
  listener {
    lb_port = 80
    lb_protocol = "http"
    instance_port = "80"
    instance_protocol = "http"
  }
}
