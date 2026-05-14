output "volume_id" {
  description = "EBS volume ID — add this to terraform.tfvars in the root module"
  value       = aws_ebs_volume.mysql_data.id
}

output "availability_zone" {
  description = "AZ the volume lives in — EC2 DB server must be in the same AZ"
  value       = aws_ebs_volume.mysql_data.availability_zone
}

output "s3_bucket_name" {
  description = "S3 media bucket name — automatically used by deploy.sh"
  value       = aws_s3_bucket.media.bucket
}

output "s3_bucket_url" {
  description = "Public base URL for S3 objects (AWS_URL in the app .env)"
  value       = "https://${aws_s3_bucket.media.bucket}.s3.${var.aws_region}.amazonaws.com"
}
