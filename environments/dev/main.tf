module "vpc" {
    source = "../../modules/networking"
    eks_name = var.eks_name
    environment = var.environment
    project = var.project
    cidr_vpc = var.cidr_vpc
}

module "jenkins" {
    source = "../../modules/jenkins"
    subnet_id = module.vpc.vpc_public_subnets[0]
    vpc_id = module.vpc.vpc_id
    cidr_vpc = [module.vpc.vpc_cidr_block]
}

module "ecr"{
    source = "../../modules/ecr"
    environment = var.environment
    project = var.project
}

module "eks"{
    source = "../../modules/eks-cluster"
    environment = var.environment
    project = var.project
    eks_name = var.eks_name
    vpc_id = module.vpc.vpc_id
    vpc_intra_subnets = module.vpc.vpc_intra_subnets[*]
    vpc_private_subnets = module.vpc.vpc_private_subnets
    
}