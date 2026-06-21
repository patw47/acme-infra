resource "aws_ecr_repository" "acme_app" {
  name                 = "acme-app"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = merge(local.tags, { Name = "acme-app" })
}

output "ecr_repository_url" {
  value = aws_ecr_repository.acme_app.repository_url
}
