# heavily 'inspired by' https://github.com/kenhalbert/terraform-ec2-nat-instance/blob/main/main.tf

# EIPs to be passed in from calling module, so they can be switched between nat
# instances defined here or nat gateways defined there

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

resource "aws_security_group" "nat_security_group" {
  #name_prefix has a picosecond suffix... really guys? 26 chars from YYYY on down...
  name_prefix = "nat-${var.ou}-${var.env}-"
  description = "NAT instances for VPCs"
  vpc_id      = var.vpc_id

  ingress = [
    {
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = [var.vpc_cidr]
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      self             = true
      description      = ""
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

# resource "aws_network_interface" "nat_network_interface" {
#     subnet_id = var.subnet_id
#     source_dest_check = false
#     security_groups = [aws_security_group.nat_security_group.id]

#     tags {
#         Name = "nat-${var.subnet_id}"
#     }
# }

# resource "aws_key_pair" "nat_ssh_key" {
#     key_name = "nat-instance"
#     public_key = var.nat_ssh_pubkey
# }

resource "aws_eip_association" "nat_eip" {
  instance_id   = aws_instance.nat_instance.id
  allocation_id = var.eip
}

# role allows shell access via SSM/web console
resource "aws_iam_role" "nat_role" {
  name = "ec2-nat-role"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17"
    "Statement" : [
      {
        "Effect" : "Allow"
        "Action" : "sts:AssumeRole"
        "Principal" : {
          "Service" : ["ec2.amazonaws.com"]
        }
      }
    ]
  })
  managed_policy_arns = ["arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"]
}

resource "aws_iam_instance_profile" "nat_instance_profile" {
  name = "ec2-nat-profile"
  role = aws_iam_role.nat_role.name
}

resource "aws_instance" "nat_instance" {
  ami                         = var.nat_instance_config.ami_id
  subnet_id                   = var.subnet_id
  instance_type               = var.nat_instance_config.instance_type
  iam_instance_profile        = aws_iam_instance_profile.nat_instance_profile.id
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.nat_security_group.id]
  key_name                    = var.keypair

  source_dest_check = false

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
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
sysctl -p
/usr/bin/apt-get update
DEBIAN_FRONTEND=noninteractive /usr/bin/apt-get install -y iptables-persistent
/usr/sbin/iptables -t nat -A POSTROUTING -j MASQUERADE
/usr/sbin/iptables-save > /etc/iptables/rules.v4
EOT

  tags = {
    Name = "vpc-nat-${var.ou}-${var.env}"
  }
}
