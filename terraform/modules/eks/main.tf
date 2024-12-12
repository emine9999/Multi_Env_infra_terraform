resource "aws_eks_cluster" "main" {
  count = length(var.private_subnet_ids)

  name     = "eks-cluster-${var.environment[0]}-${count.index + 1}"
  role_arn = aws_iam_role.eks_cluster.arn
  version  = "1.27"

  vpc_config {
    subnet_ids              = [var.private_subnet_ids[count.index]]
    endpoint_private_access = true
    endpoint_public_access  = true
    vpc_id                 = var.vpc_id
    security_group_ids     = [aws_security_group.eks_cluster[count.index].id]
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy
  ]
}

# Node Groups
resource "aws_eks_node_group" "main" {
  count = length(var.private_subnet_ids)

  cluster_name    = aws_eks_cluster.main[count.index].name
  node_group_name = "node-group-${var.environment[0]}-${count.index + 1}"
  node_role_arn   = aws_iam_role.eks_node_group.arn
  subnet_ids      = [var.private_subnet_ids[count.index]]

  scaling_config {
    desired_size = var.environment[0] == "dev" ? 1 : 2
    min_size     = 1
    max_size     = var.environment[0] == "dev" ? 2 : 3
  }

  instance_types = ["t3.medium"]

  depends_on = [
    aws_iam_role_policy_attachment.eks_node_group_policy,
    aws_iam_role_policy_attachment.eks_cni_policy,
    aws_iam_role_policy_attachment.eks_container_registry,
  ]
}

resource "aws_lb" "eks" {
  count = length(var.private_subnet_ids)

  name               = "alb-${var.environment[0]}-${count.index + 1}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb[count.index].id]
  subnets           = [var.public_subnet_ids[count.index]]

  tags = {
    Name = "alb-${var.environment[0]}-${count.index + 1}"
  }
}

# Security Groups
resource "aws_security_group" "eks_cluster" {
  count  = length(var.private_subnet_ids)
  name   = "eks-cluster-sg-${var.environment[0]}-${count.index + 1}"
  vpc_id = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group_rule" "eks_cluster_ingress" {
  count = length(var.private_subnet_ids)

  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb[count.index].id
  security_group_id        = aws_security_group.eks_cluster[count.index].id
}

resource "aws_security_group" "alb" {
  count  = length(var.private_subnet_ids)
  name   = "alb-sg-${var.environment[0]}-${count.index + 1}"
  vpc_id = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
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

# IAM Roles and Policies
resource "aws_iam_role" "eks_cluster" {
  name = "eks-cluster-role-${var.environment[0]}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "eks.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster.name
}

resource "aws_iam_role" "eks_node_group" {
  name = "eks-node-group-role-${var.environment[0]}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_node_group_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_node_group.name
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_node_group.name
}

resource "aws_iam_role_policy_attachment" "eks_container_registry" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_node_group.name
}