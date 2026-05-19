output "ecr_api_url" {
  value = aws_ecr_repository.api.repository_url
}

output "ecr_fe_url" {
  value = aws_ecr_repository.fe.repository_url
}