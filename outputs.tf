output "app_public_ip" {
  description = "Public IP of the app server"
  value       = aws_instance.app.public_ip
}

output "db_public_ip" {
  description = "Public IP of the MySQL server (for SSH only)"
  value       = aws_instance.db.public_ip
}

output "db_private_ip" {
  description = "Private IP of the MySQL server (used internally by the app server)"
  value       = aws_instance.db.private_ip
}

output "app_url" {
  description = "Restaurant app URL"
  value       = "http://${aws_instance.app.public_ip}"
}

output "websocket_url" {
  description = "Laravel Reverb WebSocket URL"
  value       = "ws://${aws_instance.app.public_ip}:8080"
}

output "ssh_app" {
  description = "SSH command — app server"
  value       = "ssh -i ~/.ssh/terraform-key ubuntu@${aws_instance.app.public_ip}"
}

output "ssh_db" {
  description = "SSH command — MySQL server"
  value       = "ssh -i ~/.ssh/terraform-key ubuntu@${aws_instance.db.public_ip}"
}

output "next_steps" {
  description = "What to do after the environment is up"
  value       = <<-EOT
    1. Wait ~3 min for user_data scripts to finish on both servers
    2. SSH into the app server:
         ssh -i ~/.ssh/terraform-key ubuntu@${aws_instance.app.public_ip}
    3. Run the deploy script:
         sudo /opt/restaurant/deploy.sh
    4. Visit: http://${aws_instance.app.public_ip}
  EOT
}

