provider "aws" {
  region = "ap-southeast-2"
  assume_role {
    role_arn = "arn:aws:iam::${var.aws_account_id}:role/terraform-deploy-superadmin"
  }
  default_tags {
    tags = {
      env                  = var.env
      terraform-stack-name = "${var.ou}-${var.env}-${basename(abspath(path.module))}"
      ou                   = var.ou
      cost-centre          = var.cost_centre
    }
  }
}

data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = "aaa-terraform"
    key    = "${var.ou}/${var.env}/aws-vpc/terraform.tfstate"
    region = var.aws_region
  }
}

data "aws_ami" "debian" {
  # ami images, information: https://wiki.debian.org/Cloud/AmazonEC2Image/Bookworm
  most_recent = true

  filter {
    name   = "name"
    values = var.ami_filter_strings
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = var.ami_owners
}
resource "aws_instance" "opsnode" {
  ami                     = data.aws_ami.debian.id
  instance_type           = var.instance_type
  disable_api_termination = var.disable_api_termination
  iam_instance_profile    = aws_iam_instance_profile.opsnode.id
  vpc_security_group_ids  = [aws_security_group.opsnode.id]
  key_name                = var.ec2_keypair
  # TODO: figure out how to select a subnet specifically for AZ 'a'
  subnet_id = data.terraform_remote_state.vpc.outputs.private_subnets[0]

  root_block_device {
    volume_type = var.ec2_root_volume_type
    volume_size = var.ec2_root_volume_size
  }

  tags = {
    Name = "ops-node (troubleshooter)"
  }
  lifecycle {
    ignore_changes = [
      # the AMI lookup will change over time
      ami
    ]
  }

  # sleep 20 is because sometimes the network is not available by the time the bootscript runs
  # this script is DEBIAN/UBUNTU-specific (dpkg/apt/deb)
  user_data = <<EOT
#!/bin/bash
set -e
sleep 20
wget https://s3.ap-southeast-2.amazonaws.com/amazon-ssm-ap-southeast-2/latest/debian_$(dpkg --print-architecture)/amazon-ssm-agent.deb
dpkg -i amazon-ssm-agent.deb
systemctl enable amazon-ssm-agent
systemctl start amazon-ssm-agent
EOT
}
resource "aws_iam_instance_profile" "opsnode" {
  name = "ec2-opsnode-profile"
  role = aws_iam_role.opsnode.name
}
resource "aws_iam_role" "opsnode" {
  name = "ec2-opsnode"
  # allow AWS Systems Manager to connect sessions
  managed_policy_arns = ["arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"]
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_security_group" "opsnode" {
  #name_prefix has a picosecond suffix... really guys? 26 chars from YYYY on down...
  name_prefix = "ec2-opsnode"
  description = "opsnodes"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id

  ingress = [
    {
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["172.30.0.0/16"] # TODO: parametise this
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      self             = true
      description      = "internal network"
      security_groups  = []
    },
    {
      from_port        = "-1"
      to_port          = "-1"
      protocol         = "icmp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      self             = true
      description      = ""
      security_groups  = []
    }
  ]

  egress = [
    {
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      self             = true
      description      = ""
      security_groups  = []
    }
  ]
}