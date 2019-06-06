provider "aws" {
  access_key = var.access_key
  secret_key = var.secret_key
  region     = var.region
}

resource "aws_security_group" "default" {
  name        = "terraform_example"
  description = "Used in the terraform"

  # SSH access from anywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP access from the VPC
  ingress {
    from_port   = 4000
    to_port     = 4000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "example" {
  
  connection {
    user = "ec2-user"
    host = self.public_ip
    private_key = file("../aws-elb-2019-06-06.pem")
  }

  ami = "ami-005930c8f6eb929ba"
  instance_type = "t2.micro"
  
  key_name = "aws-elb-2019-06-06"

  vpc_security_group_ids = ["${aws_security_group.default.id}"]

  provisioner "remote-exec" {
    inline = [
      "docker pull tianbiao/friendlyhello",
      "docker run -d -p 4000:80 tianbiao/friendlyhello",
    ]
  }
}

resource "aws_eip" "ip" {
  instance = aws_instance.example.id
}

