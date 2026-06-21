resource "aws_apprunner_vpc_connector" "acme_app_vpc_connector" {
  vpc_connector_name = "${var.environment}-vpc-connector"
  subnets            = concat(module.vpc.database_subnets, module.vpc.private_subnets, module.vpc.public_subnets)
  security_groups    = [module.app_security_group.security_group_id]
}

resource "aws_apprunner_service" "acme_app_service" {
  depends_on   = [aws_ecr_repository.acme_app]
  service_name = "acme-app"

  source_configuration {
    image_repository {
      image_configuration {
        port = "8000"
        runtime_environment_variables = {
          PG_PASSWORD = var.pg_password
        }
      }
      image_identifier      = "111122223333.dkr.ecr.us-east-1.amazonaws.com/acme-app:v1.0.0"
      image_repository_type = "ECR"
    }

    authentication_configuration {
      access_role_arn = aws_iam_role.acme_apprunner_service_role.arn
    }

    auto_deployments_enabled = true
  }

  instance_configuration {
    instance_role_arn = aws_iam_role.acme_app_runner_role.arn
    cpu               = "2 vCPU"
    memory            = "4 GB"
  }

  network_configuration {
    egress_configuration {
      egress_type       = "VPC"
      vpc_connector_arn = aws_apprunner_vpc_connector.acme_app_vpc_connector.arn
    }
  }

  tags = local.tags
}

output "apprunner_service_url" {
  value       = aws_apprunner_service.acme_app_service.service_url
  description = "URL of the App Runner service"
}
