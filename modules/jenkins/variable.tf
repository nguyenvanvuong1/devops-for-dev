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
  type    = list(string)
}

variable "vpc_id" {
  type    = string
}

variable "subnet_id" {
  type    = string
}
