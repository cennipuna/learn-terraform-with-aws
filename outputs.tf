output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.web_server.id
}

output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.web_server.public_ip
}

output "nginx_url" {
  description = "URL to access Nginx"
  value       = "http://${aws_instance.web_server.public_ip}:8089"
}

output "ssh_command" {
  description = "SSH command to connect to the instance"
  value       = "ssh -i ~/.ssh/terraform-key ubuntu@${aws_instance.web_server.public_ip}"
}
