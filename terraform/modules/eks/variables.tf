variable "environment" {
  type = list(string)
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "public_subnet_ids" {
  type = list(string)
  description = "Public subnet IDs for ALB"
}

variable "vpc_id" {
  type = string
}