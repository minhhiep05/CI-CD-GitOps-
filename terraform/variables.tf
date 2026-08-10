variable "aws_region"        { default = "us-east-1" }
variable "key_pair_name"     { default = "lab" }
variable "vpc_cidr"          { default = "10.0.0.0/16" }
variable "instance_type_k8s" { default = "c7i-flex.large" }
variable "admin_cidr" {
  description = "IP admin được SSH/gọi API server"
  default     = "18.209.16.19/32"
}
