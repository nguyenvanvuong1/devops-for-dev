### define variable su dung
variable "project" {
  type    = string
  default = "vuongnvpractice"
}
variable "environment" {
  type    = string
  default = "vuongnv"
}
variable "oidc_provider_arn" {
  type = string
}
variable "cluster_endpoint" {
  type = string
}
variable "cluster_certificate_authority_data" {
  type = string
}
variable "cluster_name" {
  type = string
}
