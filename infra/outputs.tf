output "ecr_repository_url" {
  value = aws_ecr_repository.repo.repository_url
}

output "apprunner_service_url" {
  value = aws_apprunner_service.service.service_url
}

output "github_oidc_role_arn" {
  value = aws_iam_role.gha_role.arn
}

output "aws_region" {
  value = var.aws_region
}

