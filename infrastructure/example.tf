provider "aws" {
  access_key = var.access_key
  secret_key = var.secret_key
  region     = var.region
}

resource "aws_vpc" "default" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_internet_gateway" "default" {
  vpc_id = "${aws_vpc.default.id}"
}

resource "aws_route" "internet_access" {
  route_table_id         = "${aws_vpc.default.main_route_table_id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.default.id}"
}

resource "aws_subnet" "default" {
  vpc_id                  = "${aws_vpc.default.id}"
  cidr_block              = "10.0.1.0/24"
  availability_zone = "${var.region}a"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "another" {
  vpc_id                  = "${aws_vpc.default.id}"
  cidr_block              = "10.0.2.0/24"
  availability_zone = "${var.region}b"
  map_public_ip_on_launch = true
}

resource "aws_security_group" "elb" {
  name        = "terraform_example_elb"
  description = "Used in the terraform"
  vpc_id      = "${aws_vpc.default.id}"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "ec2_instance" {
  name        = "terraform_example"
  description = "Used in the terraform"
  vpc_id      = "${aws_vpc.default.id}"

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
    cidr_blocks = ["${aws_security_group.elb.id}"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb" "web" {
  name = "terraform-example-elb"
  internal = false
  load_balancer_type = "application"
  security_groups = ["${aws_security_group.elb.id}"]
  subnets         = ["${aws_subnet.default.id}", "${aws_subnet.another.id}"]
}

resource "aws_lb_target_group" "web" {
  name = "terraform-example-tg"
  port = 8080
  protocol = "HTTP"
  vpc_id   = "${aws_vpc.default.id}"
}

resource "aws_lb_target_group_attachment" "test" {
  target_group_arn = "${aws_lb_target_group.web.arn}"
  target_id        = "${aws_instance.example.id}"
  port             = 4000
}

resource "aws_lb_listener" "web" {
  load_balancer_arn = "${aws_lb.web.id}"
  port = "80"
  protocol = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.web.arn}"
  }
}

resource "aws_instance" "example" {
  
  connection {
    user = "ec2-user"
    host = self.public_ip
    private_key = "${file("../aws-elb-2019-06-06.pem")}"
  }

  ami = "ami-005930c8f6eb929ba"
  instance_type = "t2.micro"
  
  key_name = "aws-elb-2019-06-06"

  vpc_security_group_ids = ["${aws_security_group.ec2_instance.id}"]
  subnet_id = "${aws_subnet.default.id}"

  provisioner "remote-exec" {
    inline = [
      "docker pull tianbiao/friendlyhello",
      "docker run -d -p 4000:80 tianbiao/friendlyhello",
    ]
  }
}



