variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
}

variable "zone" {
  description = "GCP zone"
  type        = string
}

variable "vpc_name" {
  description = "VPC name"
  type        = string
  default     = "secure-vpc"
}

variable "subnet_name" {
  description = "Subnet name"
  type        = string
  default     = "secure-subnet"
}

variable "subnet_cidr" {
  description = "Subnet CIDR"
  type        = string
  default     = "10.10.0.0/24"
}

variable "firewall_name" {
  description = "Firewall rule name"
  type        = string
  default     = "allow-internal"
}
