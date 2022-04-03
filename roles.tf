################################################################################
# DevOps group, policy, and AWS role + group
################################################################################

resource "aws_iam_group" "eks_devops_group" {
  name = local.eks_devops_group
}

resource "aws_iam_group_policy" "eks_devops_group_policy" {
  name  = local.eks_devops_group_policy
  group = aws_iam_group.eks_devops_group.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        "Action": "sts:AssumeRole",
        "Effect": "Allow",
        "Resource": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${local.eks_devops_role}"
      }
    ]
  })
}

resource "aws_iam_role" "eks_devops_role" {
  name = local.eks_devops_role
  description = "DevOps master role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          "AWS":"arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
      },
    ]
  })

  inline_policy {
    name = "eks_devops_role_inline_policy"

    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action   = [
            "eks:DescribeCluster",
            "eks:ListClusters"
          ]
          Effect   = "Allow"
          Resource = "*"
        },
      ]
    })
  }
}

################################################################################
# Backend group, policy, and AWS role + group
################################################################################

resource "aws_iam_group" "eks_backend_group" {
  name = local.eks_backend_group
}

resource "aws_iam_group_policy" "eks_backend_group_policy" {
  name  = local.eks_backend_group_policy
  group = aws_iam_group.eks_backend_group.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        "Action": "sts:AssumeRole",
        "Effect": "Allow",
        "Resource": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${local.eks_backend_role}"
      }
    ]
  })
}

resource "aws_iam_role" "eks_backend_role" {
  name = local.eks_backend_role
  description = "Backend Developer role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          "AWS":"arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
      }
    ]
  })

  inline_policy {
    name = "eks_backend_role_inline_policy"

    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action   = [
            "eks:DescribeCluster",
            "eks:ListClusters"
          ]
          Effect   = "Allow"
          Resource = "*"
        },
      ]
    })
  }
}
