output "vpc_id" {
  description = "ID da VPC."
  value       = aws_vpc.main.id
}

output "ec2_instance_id" {
  description = "ID da EC2."
  value       = aws_instance.app.id
}

output "public_ip" {
  description = "IP público fixo da aplicação."
  value       = aws_eip.app.public_ip
}

output "application_url" {
  description = "URL HTTP da aplicação."
  value       = "http://${aws_eip.app.public_ip}"
}

output "rds_endpoint" {
  description = "Endpoint privado do RDS."
  value       = aws_db_instance.main.address
}

output "secret_arn" {
  description = "ARN do segredo do RDS."
  value       = aws_secretsmanager_secret.db.arn
}
