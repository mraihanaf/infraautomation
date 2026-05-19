terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

resource "aws_cloudwatch_log_group" "ecs_fe" {
  name = "/ecs/lks-fe-app"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "ecs_api" {
  name = "/ecs/lks-api-app"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "ecs_analytics" {
  name = "/ecs/lks-analytics-app"
  retention_in_days = 7
}
