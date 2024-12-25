### define variable su dung
## vpc
variable "project" {
  type    = string
  default = "vuongnvpractice"
}
variable "environment" {
  type    = string
  default = "vuongnv"
}

variable "cidr_vpc" {
  type    = string
  default = "10.0.0.0/16"
}

variable "eks_name" {
  type    = string
  default = "eks"
}

