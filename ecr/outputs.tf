output "backend_repo_url" {
  description = "ECR URL for the backend (PHP-FPM / Laravel) image"
  value       = aws_ecr_repository.backend.repository_url
}

output "frontend_repo_url" {
  description = "ECR URL for the frontend (Vue build) image"
  value       = aws_ecr_repository.frontend.repository_url
}

output "registry_id" {
  description = "AWS account ID — used as the ECR registry hostname prefix"
  value       = aws_ecr_repository.backend.registry_id
}

output "nginx_repo_url" {
  description = "ECR URL for the Nginx image"
  value       = aws_ecr_repository.nginx.repository_url
}

output "instance_profile_name" {
  description = "Attach this IAM instance profile to EC2 instances for ECR pull access"
  value       = aws_iam_instance_profile.ec2_ecr.name
}

output "push_hint" {
  description = "Reminder of where to push images"
  value       = "Run ./push.sh [tag] from this directory to build and push images"
}

output "github_actions_access_key_id" {
  description = "AWS_ACCESS_KEY_ID — add this as a GitHub Actions secret"
  value       = aws_iam_access_key.github_actions.id
}

output "github_actions_secret_access_key" {
  description = "AWS_SECRET_ACCESS_KEY — add this as a GitHub Actions secret (shown once)"
  value       = aws_iam_access_key.github_actions.secret
  sensitive   = true
}

