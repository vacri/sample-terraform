terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
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
resource "aws_instance" "jumphost" {
  ami                     = data.aws_ami.debian.id
  instance_type           = var.instance_type
  disable_api_termination = var.disable_api_termination
  iam_instance_profile    = aws_iam_instance_profile.jumphost.id
  vpc_security_group_ids  = [aws_security_group.jumphost.id]
  key_name                = var.ec2_keypair
  # TODO: figure out how to select a subnet specifically for AZ 'a'
  subnet_id = data.terraform_remote_state.vpc.outputs.public_subnets[0]

  tags = {
    Name = "jumphost"
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

resource "aws_iam_instance_profile" "jumphost" {
  name = "ec2-jumphost-profile"
  role = aws_iam_role.jumphost.name
}

resource "aws_iam_role" "jumphost" {
  name = "ec2-jumphost"
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

resource "aws_eip" "jumphost" {
  # provider v4 style
  #vpc   = true
  # provider v5 style
  domain = "vpc"
}

resource "aws_eip_association" "jumphost" {
  instance_id   = aws_instance.jumphost.id
  allocation_id = aws_eip.jumphost.id
}

# resource "aws_iam_role_policy_attachment" "AmazonSSMManagedInstanceCore" {
#   role       = aws_iam_role.ecs_task_role.name
#   policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
# }

resource "aws_security_group" "jumphost" {
  #name_prefix has a picosecond suffix... really guys? 26 chars from YYYY on down...
  name_prefix = "ec2-jumphost"
  description = "jumphosts"
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
      from_port        = 22
      to_port          = 22
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      self             = true
      description      = "public ssh"
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