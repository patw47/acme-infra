# ── CLEAN BASELINE ──────────────────────────────────────────────────────────

# CLEAN: App Runner service role — scoped to ECR read + specific VPC actions
resource "aws_iam_role" "acme_apprunner_service_role" {
  name = "AcmeAppRunnerServiceRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = { Service = "build.apprunner.amazonaws.com" }
      }
    ]
  })

  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "acme_apprunner_ecr_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.acme_apprunner_service_role.name
}

resource "aws_iam_role_policy" "acme_apprunner_vpc_policy" {
  name = "acme-apprunner-vpc-policy"
  role = aws_iam_role.acme_apprunner_service_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateNetworkInterface",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DeleteNetworkInterface",
          "ec2:AssignPrivateIpAddresses",
          "ec2:UnassignPrivateIpAddresses"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role" "acme_app_runner_role" {
  name = "acme-app-runner-instance-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = { Service = "tasks.apprunner.amazonaws.com" }
      }
    ]
  })

  tags = local.tags
}

# CLEAN: tightly scoped policy — specific actions on a specific S3 bucket ARN
resource "aws_iam_policy" "acme_scoped_s3_policy" {
  name        = "acme-scoped-s3-read"
  description = "Allows read-only access to a single S3 bucket prefix"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["s3:GetObject", "s3:ListBucket"]
        Resource = [
          "arn:aws:s3:::acme-private-data-${var.environment}",
          "arn:aws:s3:::acme-private-data-${var.environment}/reports/*"
        ]
      }
    ]
  })

  tags = local.tags
}

# ── TRUE RED FLAG ────────────────────────────────────────────────────────────

# RED FLAG: wildcard Action and Resource — effectively grants full AWS access
resource "aws_iam_policy" "acme_wildcard_policy" {
  name        = "acme-wildcard-admin"
  description = "INSECURE: grants all actions on all resources"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "*"
        Resource = "*"
      }
    ]
  })

  tags = local.tags
}
