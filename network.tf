data "aws_caller_identity" "current" {}
data "aws_availability_zones" "available" {}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${var.environment}-vpc"
  cidr = local.vpc_cidr

  azs              = local.azs
  public_subnets   = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k)]
  private_subnets  = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 3)]
  database_subnets = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 6)]

  create_database_subnet_group   = true
  enable_nat_gateway             = true
  single_nat_gateway             = false
  one_nat_gateway_per_az         = true

  tags = local.tags
}

# ── CLEAN BASELINE ──────────────────────────────────────────────────────────

# CLEAN: web traffic on 80/443 from any source — legitimate for public LB
resource "aws_security_group" "acme_web_sg" {
  name        = "${var.environment}-web-sg"
  description = "Allow inbound HTTP and HTTPS from internet"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP from internet"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS from internet"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.tags
}

# CLEAN: SSH restricted to internal RFC-1918 range
resource "aws_security_group" "acme_internal_ssh_sg" {
  name        = "${var.environment}-internal-ssh-sg"
  description = "Allow SSH only from internal network"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]
    description = "SSH from internal network only"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.tags
}

# CLEAN: App Runner / internal service connectivity
module "app_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name        = "${var.environment}-app-sg"
  description = "Application security group"
  vpc_id      = module.vpc.vpc_id

  ingress_with_cidr_blocks = [
    {
      from_port   = 5432
      to_port     = 5432
      protocol    = "tcp"
      description = "PostgreSQL access from VPC"
      cidr_blocks = module.vpc.vpc_cidr_block
    },
  ]

  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      description = "Allow all outbound traffic"
      cidr_blocks = "0.0.0.0/0"
    },
  ]

  tags = local.tags
}

# ── TRUE RED FLAGS ───────────────────────────────────────────────────────────

# RED FLAG: SSH open to the world
resource "aws_security_group" "acme_open_ssh_sg" {
  name        = "${var.environment}-open-ssh-sg"
  description = "INSECURE: SSH open to all IPs"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "SSH from anywhere"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.tags
}

# RED FLAG: RDP open to the world
resource "aws_security_group" "acme_open_rdp_sg" {
  name        = "${var.environment}-open-rdp-sg"
  description = "INSECURE: RDP open to all IPs"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "RDP from anywhere"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.tags
}

# ── FALSE-POSITIVE TRAP ──────────────────────────────────────────────────────

# TRAP: SSH source comes from a variable — static scanners cannot resolve
# var.bastion_cidr at parse time. Must emit WARNING, not HIGH.
resource "aws_security_group" "acme_var_ssh_sg" {
  name        = "${var.environment}-var-ssh-sg"
  description = "SSH allowed from bastion CIDR (resolved via variable)"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.bastion_cidr]
    description = "SSH from bastion (CIDR in variable)"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.tags
}
