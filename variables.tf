variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "dev"
}

variable "pg_db_name" {
  description = "PostgreSQL database name"
  type        = string
  default     = "acmedb"
}

variable "pg_username" {
  description = "PostgreSQL master username"
  type        = string
  default     = "acmeadmin"
}

variable "pg_password" {
  description = "PostgreSQL master password"
  type        = string
  sensitive   = true
}

variable "pg_port" {
  description = "PostgreSQL port"
  type        = number
  default     = 5432
}

# FALSE-POSITIVE TRAP: SSH CIDR supplied via variable — static scanners
# cannot resolve this at parse time; must emit WARNING not HIGH.
variable "bastion_cidr" {
  description = "CIDR block allowed to SSH to bastion host"
  type        = string
  default     = "10.0.1.0/24"
}
