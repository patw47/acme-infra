data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

# ── CLEAN BASELINE ──────────────────────────────────────────────────────────

# CLEAN: bastion behind internal-SSH security group, no secrets in user_data
resource "aws_instance" "acme_bastion" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t3.micro"
  subnet_id              = module.vpc.public_subnets[0]
  vpc_security_group_ids = [aws_security_group.acme_internal_ssh_sg.id]

  metadata_options {
    http_tokens = "required"
  }

  tags = merge(local.tags, { Name = "acme-bastion" })
}

# ── TRUE RED FLAG ────────────────────────────────────────────────────────────

# RED FLAG: hardcoded fake AWS access key in user_data
resource "aws_instance" "acme_insecure_ec2" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t3.small"
  subnet_id              = module.vpc.public_subnets[0]
  vpc_security_group_ids = [aws_security_group.acme_open_ssh_sg.id]

  user_data = <<-EOF
    #!/bin/bash
    export AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE
    export AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
    aws s3 cp s3://acme-deploy-artifacts/app.tar.gz /opt/app/
  EOF

  tags = merge(local.tags, { Name = "acme-insecure-worker" })
}
