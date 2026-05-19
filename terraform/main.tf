# ═══════════════════════════════════════════════════════════
#  ROOT MAIN.TF — Application Infrastructure (us-east-1)
#
#  Terraform manages:
#    VPC, Security Groups, ALB, RDS, DynamoDB, SQS, S3, SSM
#
#  NOT included in this task (managed separately):
#    ECR, ECS, Monitoring VPC, VPC Peering
# ═══════════════════════════════════════════════════════════

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "lks2026"
      Environment = "production"
      ManagedBy   = "Terraform"
    }
  }
}

# ── 1. Application VPC — us-east-1 ───────────────────────
module "vpc" {
  source = "./modules/vpc"

  vpc_name              = "lks-vpc"
  vpc_cidr              = var.vpc_cidr
  public_subnet_cidrs   = var.public_subnet_cidrs
  private_subnet_cidrs  = var.private_subnet_cidrs
  isolated_subnet_cidrs = var.isolated_subnet_cidrs
  availability_zones    = var.availability_zones
}

module "monitoring_vpc" {
  source = "./modules/monitoring_vpc"
  private_subnet_cidrs = ["10.1.1.0/24","10.1.2.0/24"]
  availability_zones = ["us-west-2a", "us-west-2b"]
}

# ── 2. Security Groups — us-east-1 ───────────────────────
module "security" {
  source = "./modules/security"

  vpc_id              = module.vpc.vpc_id
  monitoring_vpc_cidr = var.monitoring_vpc_cidr
}

# ── 3. Application Load Balancer — us-east-1 ─────────────
module "alb" {
  source = "./modules/alb"

  alb_name          = "lks-alb"
  public_subnet_ids = module.vpc.public_subnet_ids
  security_group_id = module.security.sg_alb_id
  vpc_id            = module.vpc.vpc_id
}

# ── 4. Database & Supporting Resources — us-east-1 ───────
module "database" {
  source = "./modules/database"

  vpc_id              = module.vpc.vpc_id
  isolated_subnet_ids = module.vpc.isolated_subnet_ids
  private_subnet_ids  = module.vpc.private_subnet_ids
  security_group_id   = module.security.sg_db_id

  db_name           = var.db_name
  db_username       = var.db_username
  db_password       = var.db_password
  db_instance_class = var.db_instance_class

  sqs_queue_name = "lks-event-queue"
  dlq_name       = "lks-dlq"
  dynamo_table   = "lks-sessions"
}

# ── 5. S3 Buckets — us-east-1 ────────────────────────────
module "s3" {
  source = "./modules/s3"

  tfstate_bucket_name = "lks-tfstate-${var.student_name}-2026"
  assets_bucket_name  = "lks-app-assets-${var.student_name}-2026"
}

module "ecr" {
  source = "./modules/ecr"
}

module "vpc_peering" {
  source = "./modules/vpc_peering"
  vpc_east_id = module.vpc.vpc_id
  vpc_west_id = module.monitoring_vpc.vpc_id
}

module "sns" {
  source = "./modules/sns"
}

module "cloudwatch" {
  source = "./modules/cloudwatch"
}