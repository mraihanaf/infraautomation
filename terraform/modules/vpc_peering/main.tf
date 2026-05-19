terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
    region = "us-west-2"
    alias = "west"
}


resource "aws_vpc_peering_connection" "peer" {
  vpc_id        = var.vpc_east_id
  peer_vpc_id   = var.vpc_west_id
  peer_owner_id = data.aws_caller_identity.peer.account_id
  peer_region   = "us-west-2"
  auto_accept   = false

  tags = {
    Side = "Requester"
  }
}

resource "aws_vpc_peering_connection_accepter" "peer" {
  provider                  = aws.west
  vpc_peering_connection_id = aws_vpc_peering_connection.peer.id
  auto_accept               = true

  tags = {
    Side = "Accepter"
  }
}


data "aws_caller_identity" "peer" {
  provider = aws.west
}


resource "aws_route_table" "west" {
  provider = aws.west
  vpc_id = var.vpc_west_id
  route {
    cidr_block = "10.0.3.0/24"
    gateway_id = aws_vpc_peering_connection_accepter.peer.id
  }

  route {
    cidr_block = "10.0.4.0/24"
    gateway_id = aws_vpc_peering_connection_accepter.peer.id
  }
  tags = { Name = "lks-peer-rt" }
}

resource "aws_route_table" "east" {
  vpc_id = var.vpc_east_id
  route {
    cidr_block = "10.1.1.0/24"
    gateway_id = aws_vpc_peering_connection.peer.id
  }

  route {
    cidr_block = "10.1.2.0/24"
    gateway_id = aws_vpc_peering_connection.peer.id
  }
  tags = { Name = "lks-peer-rt" }
}





