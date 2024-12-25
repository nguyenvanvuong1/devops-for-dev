module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  name   = "${var.project}-${var.environment}-vpc"
  cidr   = var.cidr_vpc

  azs             = local.azs
  private_subnets = [for k, v in local.azs : cidrsubnet(var.cidr_vpc, 4, k)]
  public_subnets  = [for k, v in local.azs : cidrsubnet(var.cidr_vpc, 8, k + 48)]
  intra_subnets   = [for k, v in local.azs : cidrsubnet(var.cidr_vpc, 8, k + 52)]

  enable_nat_gateway = true
  single_nat_gateway = var.environment == "dev" ? true : false
  # enable_vpn_gateway = true

  enable_dns_hostnames = true
  enable_dns_support   = true


  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1

  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
    "karpenter.sh/discovery"          = var.eks_name
  }


}

