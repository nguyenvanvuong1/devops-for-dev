### define variable su dung
variable "project" {
  type    = string
  default = "vuongnvpractice"
}
variable "environment" {
  type    = string
  default = "vuongnv"
}

variable "eks_name" {
  type    = string
}

variable "cluster_version" {
  type    = string
  default = "1.30"
}

variable "vpc_id" {
  type    = string
}
variable "vpc_intra_subnets" {
  type    = list(string)
}
variable "vpc_private_subnets" {
  type    = list(string)
}

variable "ingress_instance_types" {
  type = list(string)
  default =   [
    "t3.medium"
  ]
  
}

variable "ingress_min_size" {
  type = number
  default = 1
}

variable "ingress_desired_size" {
  type = number
  default = 1
}

variable "ingress_max_size" {
  type = number
  default = 1
}


variable "workload_instance_types" {
  type = list(string)
  default =   [
    "t3.medium",
    "t3.large",
    "m5.large"
  ]
}


variable "workload_min_size" {
  type = number
  default = 3
}

variable "workload_desired_size" {
  type = number
  default = 3
}

variable "workload_max_size" {
  type = number
  default = 3
}