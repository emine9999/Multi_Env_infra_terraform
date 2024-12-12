variable "environment" {
  type = list(string)
}

variable "bucket_name" {
  type = string
  description = "Base name for the S3 bucket"
}