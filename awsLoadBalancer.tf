# Create load balancer that exposes the web interface of the container
resource "aws_internet_gateway" "gateway" {
    vpc_id = aws_vpc.main.id
}

resource "aws_lb" "front" {
    name               = "ianjaffe-lb-asg"
    internal           = false
    load_balancer_type = "application"
    security_groups    = [aws_security_group.sg_for_elb.id]
    subnets            = [aws_subnet.public_subnet_1a.id, aws_subnet.public_subnet_1b.id]
    depends_on         = [aws_internet_gateway.gateway]
}

resource "aws_lb_target_group" "front" {
    name     = "application-front"
    port     = 80
    protocol = "HTTP"
    vpc_id   = aws_vpc.main.id
}

resource "aws_lb_listener" "aws_front_end" {
    load_balancer_arn = aws_lb.front.arn
    port              = "80"
    protocol          = "HTTP"
    default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.front.arn
    }
}

resource "aws_security_group" "sg_for_elb" {
    name   = "ianjaffe-sg_for_elb"
    vpc_id = aws_vpc.main.id

    ingress {
        description      = "Allow http request from anywhere"
        protocol         = "tcp"
        from_port        = 80
        to_port          = 80
        cidr_blocks      = ["0.0.0.0/0"]
        ipv6_cidr_blocks = ["::/0"]
    }

    ingress {
        description      = "Allow https request from anywhere"
        protocol         = "tcp"
        from_port        = 443
        to_port          = 443
        cidr_blocks      = ["0.0.0.0/0"]
        ipv6_cidr_blocks = ["::/0"]
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_security_group" "sg_for_ec2" {
    name   = "ianjaffe-sg_for_ec2"
    vpc_id = aws_vpc.main.id

    ingress {
        description     = "Allow http request from Load Balancer"
        protocol        = "tcp"
        from_port       = 80 # range of
        to_port         = 80 # port numbers
        security_groups = [aws_security_group.sg_for_elb.id]
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_lb_target_group_attachment" "attach-web_instance" {
    target_group_arn = "aws_lb_target_group.front.arn"
    target_id = aws_instance.web_instance.id
    port = 80
}