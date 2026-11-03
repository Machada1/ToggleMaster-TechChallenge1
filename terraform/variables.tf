variable "aws_region" {
  description = "Região AWS da implantação."
  type        = string
  default     = "us-east-1"
}

variable "availability_zone_a" {
  description = "AZ da subnet pública e da primeira subnet privada."
  type        = string
  default     = "us-east-1a"
}

variable "availability_zone_b" {
  description = "AZ da segunda subnet privada."
  type        = string
  default     = "us-east-1b"
}

variable "repository_url" {
  description = "URL HTTPS/SSH do repositório que contém o diretório deploy."
  type        = string
}

variable "key_name" {
  description = "Nome de um key pair EC2 já existente."
  type        = string
}

variable "admin_cidr" {
  description = "IP administrativo permitido no SSH, em formato x.x.x.x/32."
  type        = string
}

variable "instance_type" {
  description = "Tipo da instância EC2."
  type        = string
  default     = "t3.micro"
}

variable "db_instance_class" {
  description = "Classe da instância RDS."
  type        = string
  default     = "db.t3.micro"
}

variable "db_username" {
  description = "Usuário administrador inicial do PostgreSQL."
  type        = string
  default     = "togglemaster_admin"
}

variable "db_name" {
  description = "Nome do banco inicial."
  type        = string
  default     = "togglemaster"
}

variable "db_password" {
  description = "Senha do RDS. Se omitida, Terraform gera uma senha aleatória."
  type        = string
  sensitive   = true
  default     = null
}

variable "rds_storage_gb" {
  description = "Armazenamento gp3 do RDS em GiB."
  type        = number
  default     = 20
}

variable "ec2_root_volume_gb" {
  description = "Armazenamento gp3 do volume raiz da EC2."
  type        = number
  default     = 12
}

variable "deletion_protection" {
  description = "Proteção contra exclusão do RDS."
  type        = bool
  default     = false
}

variable "skip_final_snapshot" {
  description = "Não criar snapshot final ao destruir o RDS. Use false em produção."
  type        = bool
  default     = true
}
