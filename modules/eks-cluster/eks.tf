data "aws_ssm_parameter" "github_token" {
  name            = "${var.project}-${var.environment}-github-token"
  with_decryption = false
}

# https://github.com/terraform-aws-modules/terraform-aws-eks/blob/master/examples/karpenter/main.tf
resource "aws_iam_user" "eks_user" {
  name = "eks_user"
}

data "aws_ecrpublic_authorization_token" "token" {
  provider = aws.virginia
}

# Create an IAM role

resource "aws_iam_role" "eks_role" {
  name = "eks-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Attach the IAM policy to the IAM role
resource "aws_iam_policy_attachment" "eks_role_policy_attachment" {
  name = "Policy Attachement"
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy",
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  ])
  roles      = [aws_iam_role.eks_role.name]
  policy_arn = each.value
  users      = [aws_iam_user.eks_user.name]
}



module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.17.2"

  cluster_name    = var.eks_name
  cluster_version = var.cluster_version

  cluster_endpoint_public_access = true

  vpc_id                   = var.vpc_id
  control_plane_subnet_ids = var.vpc_intra_subnets
  subnet_ids               = var.vpc_private_subnets

  eks_managed_node_groups = {
    ingress = {
      name         = "${var.environment}-ingress"
      min_size     = var.ingress_min_size
      max_size     = var.ingress_max_size
      desired_size = var.ingress_desired_size

      instance_types = var.ingress_instance_types
      capacity_type  = "SPOT" ### Type of capacity associated with the EKS Node Group. Valid values: ON_DEMAND, SPOT

      metadata_options = {
        http_endpoint               = "enabled"
        http_tokens                 = "required"
        http_put_response_hop_limit = 2
        instance_metadata_tags      = "disabled"
      }

      create_iam_role          = true
      iam_role_name            = "eks-managed-node-group-ingress"
      iam_role_use_name_prefix = false
      iam_role_description     = "EKS managed node group ingress role"
      iam_role_tags = {
        Purpose = "Protector of the kubelet"
      }
      iam_role_additional_policies = {
        AmazonEBSCSIDriverPolicy           = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
      }


      taints = {
        dedicated = {
          key    = "dedicated"
          value  = "ingress"
          effect = "NO_SCHEDULE"
        }
      }

      labels = {
        # NOTE - if creating multiple security groups with this module, only tag the
        # security group that Karpenter should utilize with the following tag
        # (i.e. - at most, only one security group should have this tag in your account)
        nodegroup = "ingress"
        Terraform = "True"
      }
    }
    workload = {
      name         = "${var.environment}-workload"
      min_size     = var.workload_min_size
      max_size     = var.workload_max_size
      desired_size = var.workload_desired_size

      instance_types = var.workload_instance_types
      capacity_type  = "SPOT" ### Type of capacity associated with the EKS Node Group. Valid values: ON_DEMAND, SPOT

      create_iam_role          = true
      iam_role_name            = "eks-managed-node-group-workload"
      iam_role_use_name_prefix = false
      iam_role_description     = "EKS managed node group workload role"
      iam_role_tags = {
        Purpose = "Protector of the kubelet"
      }
      iam_role_additional_policies = {
        AmazonEBSCSIDriverPolicy           = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
      }

      labels =  {
        # NOTE - if creating multiple security groups with this module, only tag the
        # security group that Karpenter should utilize with the following tag
        # (i.e. - at most, only one security group should have this tag in your account)
        nodegroup = "workload"
        Terraform = "True"
      }
      # update_config = {
      #   max_unavailable_percentage = 33 # or set `max_unavailable`
      # }
      ebs_optimized     = true
      enable_monitoring = true
    }

  }

  # Fargate Profile(s)
  fargate_profiles = {
    default = {
      name = "fargate"
      selectors = [
        {
          namespace = "fargate"
        }
      ]
    }
  }

  # aws-auth configmap
  manage_aws_auth_configmap = true

  aws_auth_roles = [
    # {
    #   rolearn  = module.karpenter.role_arn
    #   username = "system:node:{{EC2PrivateDNSName}}"
    #   groups = [
    #     "system:bootstrappers",
    #     "system:nodes",
    #   ]
    # },
    {
      rolearn  = "${aws_iam_role.eks_role.arn}"
      username = "role1"
      groups   = ["system:masters"]
    }
  ]

  aws_auth_users = [
    {
      userarn  = "${aws_iam_user.eks_user.arn}"
      username = "eks_user"
      groups   = ["system:masters"]
    },
  ]


  tags = {
    # NOTE - if creating multiple security groups with this module, only tag the
    # security group that Karpenter should utilize with the following tag
    # (i.e. - at most, only one security group should have this tag in your account)
    "karpenter.sh/discovery" = var.eks_name
    "Terraform"              = "True"
  }
}


### eks addons
module "eks_blueprints_addons" {
  source = "aws-ia/eks-blueprints-addons/aws"

  cluster_name      = module.eks.cluster_name
  cluster_endpoint  = module.eks.cluster_endpoint
  cluster_version   = module.eks.cluster_version
  oidc_provider_arn = module.eks.oidc_provider_arn

  eks_addons = {
    aws-ebs-csi-driver = {
      most_recent = true
    }
    coredns = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
  }
  # enable_aws_load_balancer_controller    = true
  enable_cluster_autoscaler = true
  # enable_cluster_proportional_autoscaler = true
  enable_kube_prometheus_stack        = true
  enable_metrics_server               = true
  tags = {
    # NOTE - if creating multiple security groups with this module, only tag the
    # security group that Karpenter should utilize with the following tag
    # (i.e. - at most, only one security group should have this tag in your account)
    "Terraform" = "True"
  }
}




