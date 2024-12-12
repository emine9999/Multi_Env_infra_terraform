variable "environment" {
  type = list(string)
}

variable "db_subnet_ids" {
  type = list(string)
}

variable "vpc_id" {
  type = string
}

variable "db_instance_class" {
  type    = string
  default = "db.t2.micro"
}

variable "eks_security_group_id" {
  type = string
  description = "Security group ID of the EKS cluster"
}

variable "db_password" {
  type = string
  default = "admin"
}