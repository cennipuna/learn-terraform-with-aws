output "volume_id" {
  description = "EBS volume ID — add this to terraform.tfvars in the root module"
  value       = aws_ebs_volume.mysql_data.id
}

output "availability_zone" {
  description = "AZ the volume lives in — EC2 DB server must be in the same AZ"
  value       = aws_ebs_volume.mysql_data.availability_zone
}
