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
    subnet_ids      = [aws_subnet.private_subnet_1a.id,aws_subnet.private_subnet_1b.id,aws_subnet.public_subnet_1a.id,aws_subnet.public_subnet_1b.id]
    instance_types = ["t2.micro"]

    scaling_config {
        desired_size = 2
        max_size     = 3
        min_size     = 1
    }

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