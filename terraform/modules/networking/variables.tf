variable "vpc_cidr_blocks" {
  description = "List of CIDR blocks for the VPCs"
  type        = list(string)
  default     = ["10.0.0.0/16", "10.1.0.0/16", "10.2.0.0/16"]
}

variable "environment" {
  description = "Environment name"
  type        = list(string)
  default     = ["dev", "staging", "prod"]

}


variable "availability_zones" {
  description = "Availability Zones for each VPC"
  type        = list(list(string))
  default     = [["us-east-1a"], ["us-east-1a", "us-east-1b"], ["us-east-1a", "us-east-1b"]]  # Dev 1 AZ, Staging/Prod 2 AZs
}

variable "subnet_cidrs" {
  description = "CIDR blocks for public, private, and database subnets"
  type        = list(list(object({
    public_cidr   = string
    private_cidr  = string
    db_cidr       = string
  })))
  default = [
    # Dev - 1 AZ
    [
      { public_cidr = "10.0.1.0/24", private_cidr = "10.0.2.0/24", db_cidr = "10.0.3.0/24" }
    ],
    # Staging - 2 AZs
    [
      { public_cidr = "10.1.1.0/24", private_cidr = "10.1.2.0/24", db_cidr = "10.1.3.0/24" },
      { public_cidr = "10.1.4.0/24", private_cidr = "10.1.5.0/24", db_cidr = "10.1.6.0/24" }
    ],
    # Prod - 2 AZs
    [
      { public_cidr = "10.2.1.0/24", private_cidr = "10.2.2.0/24", db_cidr = "10.2.3.0/24" },
      { public_cidr = "10.2.4.0/24", private_cidr = "10.2.5.0/24", db_cidr = "10.2.6.0/24" }
    ]
  ]
}