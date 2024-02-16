# Create a VPC
resource "aws_vpc" "main" {
  cidr_block = "${var.vpc_cidr}"
  
    tags = {
    Name = "ianjaffe-vpc"
  }
}

# Create public and private subnets
resource "aws_subnet" "public_subnet_1a" {
  vpc_id     = aws_vpc.main.id
  cidr_block = var.public_subnet_number_1a
  availability_zone = "us-east-1a"
}

resource "aws_subnet" "public_subnet_1b" {
  vpc_id     = aws_vpc.main.id
  cidr_block = var.public_subnet_number_1b
  availability_zone = "us-east-1b"
}

resource "aws_subnet" "private_subnet_1a" {
  vpc_id     = aws_vpc.main.id
  cidr_block = var.private_subnet_number_1a
  availability_zone = "us-east-1a"
}

resource "aws_subnet" "private_subnet_1b" {
  vpc_id     = aws_vpc.main.id
  cidr_block = var.private_subnet_number_1b
  availability_zone = "us-east-1b"
}

# EKS
resource "aws_iam_role" "EKSClusterRole" {
  name = "EKSClusterRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_eks_cluster" "ekscluster" {
  name     = "ekscluster"
  role_arn = aws_iam_role.EKSClusterRole.arn

  vpc_config {
    subnet_ids = [
      aws_subnet.public_subnet_1a.id, 
      aws_subnet.public_subnet_1b.id, 
      aws_subnet.private_subnet_1a.id, 
      aws_subnet.private_subnet_1b.id]
  }

  depends_on = [
    aws_iam_role_policy_attachment.ekscluster-AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.ekscluster-AmazonEKSVPCResourceController,
  ]
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "ekscluster" {
  name               = "eks-cluster-ekscluster"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy_attachment" "ekscluster-AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.ekscluster.name
}

resource "aws_iam_role_policy_attachment" "ekscluster-AmazonEKSVPCResourceController" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.ekscluster.name
}

resource "aws_eks_node_group" "node-ec2" {
  cluster_name    = aws_eks_cluster.ekscluster.name
  node_group_name = "t3_micro-node_group"
  node_role_arn   = aws_iam_role.NodeGroupRole.arn
  subnet_ids      = [aws_subnet.private_subnet_1a.id]

  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 1
  }

  ami_type       = "AL2_x86_64"
  instance_types = ["t3.micro"]
  capacity_type  = "ON_DEMAND"
  disk_size      = 20

  depends_on = [
    aws_iam_role_policy_attachment.AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.AmazonEC2ContainerRegistryReadOnly,
    aws_iam_role_policy_attachment.AmazonEKS_CNI_Policy
  ]
}

resource "aws_iam_role" "NodeGroupRole" {
  name = "EKSNodeGroupRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.NodeGroupRole.name
}

resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.NodeGroupRole.name
}

resource "aws_iam_role_policy_attachment" "AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.NodeGroupRole.name
}

# Container with a web interface
resource "aws_instance" "web_instance" {
  ami           = "ami-0557a15b87f6559cf"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.public_subnet_1a.id

  user_data = <<-EOF
              #!/bin/bash
              # Install Apache and host a simple website
              yum update -y
              yum install -y httpd
              service httpd start
              chkconfig httpd on
              echo "Hello, Terraform!" > /var/www/html/index.html
              EOF
}

# Create load balancer that exposes the web interface of the container
resource "aws_internet_gateway" "gateway" {
  vpc_id = aws_vpc.main.id
}

resource "aws_lb" "sh_lb" {
  name               = "ianjaffe-lb-asg"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.sh_sg_for_elb.id]
  subnets            = [aws_subnet.public_subnet_1a.id, aws_subnet.public_subnet_1b.id]
  depends_on         = [aws_internet_gateway.gateway]
}

resource "aws_lb_target_group" "sh_alb_tg" {
  name     = "sh-tf-lb-alb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
}

resource "aws_lb_listener" "sh_front_end" {
  load_balancer_arn = aws_lb.sh_lb.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.sh_alb_tg.arn
  }
}

resource "aws_security_group" "sh_sg_for_elb" {
  
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

resource "aws_security_group" "sh_sg_for_ec2" {
  name   = "ianjaffe-sg_for_ec2"
  vpc_id = aws_vpc.main.id

  ingress {
    description     = "Allow http request from Load Balancer"
    protocol        = "tcp"
    from_port       = 80 # range of
    to_port         = 80 # port numbers
    security_groups = [aws_security_group.sh_sg_for_elb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}