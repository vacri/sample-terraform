# This module is primarily intended for use with backup VMs. It has a secondary use
# for troubleshooting/general ops nodes
# Permissions for backups:
# * access to RDS databases (we allow all on local network already)
# * access to EFS-mounted filesystems
#   * the target EFS system needs to allow the security group in this module before we can mount it
# * readonly access to all s3 bucket
# * write access to the backups s3 bucket
#
# Secondary use of this module: A general ops troubleshooting node will have similar
# permissions, but can't write to the s3 backups buckets. It will have the EFS
# permissions as we have no other good/cheap way of persistently accessing EFS content directly
#
# Permission to read EFS volumes is given by the client stacks, as they need to have their security
# groups allow the SG in this stack to access port 2049 (NFS port). Those 'client' stacks search
# for a string pattern in the SG names (see fargate-web-app/efs-volumes.tf)

# TODO: stack-specific SNS topic, only for backup node


terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
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

data "terraform_remote_state" "ops_buckets" {
  backend = "s3"
  config = {
    bucket = "aaa-terraform"
    key    = "${var.ou}/${var.env}/ops-buckets/terraform.tfstate"
    region = var.aws_region
  }
}

data "terraform_remote_state" "aws_account_misc" {
  backend = "s3"
  config = {
    bucket = "aaa-terraform"
    key    = "${var.ou}/${var.env}/aws-account-misc/terraform.tfstate"
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
resource "aws_instance" "backupsnode" {
  ami                     = data.aws_ami.debian.id
  instance_type           = var.instance_type
  disable_api_termination = var.disable_api_termination
  iam_instance_profile    = aws_iam_instance_profile.backups_node.id
  vpc_security_group_ids  = [aws_security_group.ec2_backups_nodes.id]
  key_name                = var.ec2_keypair
  # TODO: figure out how to select a subnet specifically for AZ 'a'
  subnet_id = data.terraform_remote_state.vpc.outputs.private_subnets[0]

  root_block_device {
    volume_type = var.ec2_root_volume_type
    volume_size = var.ec2_root_volume_size
  }

  tags = {
    #Name = "${var.ou}-${var.env}-backups"
    Name = var.ec2_nametag
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

##
## IAM Permissions
##

resource "aws_iam_instance_profile" "backups_node" {
  name_prefix = "ec2-backups-node"
  role        = aws_iam_role.backups_node.name
}

resource "aws_iam_role" "backups_node" {
  name_prefix = "ec2-backups-node"
  # allow AWS Systems Manager to connect sessions,
  # send SNS messages,
  # access /backups/* in Secrets Manager
  managed_policy_arns = concat(
    [
      "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
      "arn:aws:iam::aws:policy/AmazonRDSReadOnlyAccess"
    ],
    [
      aws_iam_policy.efs_mounts.arn,
      aws_iam_policy.sns_alerts.arn
    ],
    var.backups_secrets_access ? [aws_iam_policy.secrets_manager[0].arn] : [],
    var.s3_backup_write_perms ? [aws_iam_policy.s3_read_all_write_backups_buckets[0].arn] : [aws_iam_policy.s3_read_all_buckets[0].arn]
  )
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

resource "aws_iam_policy" "secrets_manager" {
  count       = var.backups_secrets_access ? 1 : 0
  name_prefix = "backups-node-secrets-manager"
  policy      = <<-EOF
    {
      "Version": "2012-10-17",
      "Statement": [
        {
            "Effect": "Allow",
            "Action": [
              "secretsmanager:List*",
              "secretsmanager:Describe*"
            ],
            "Resource": "*",
            "Sid": "SecretsManager1"
        },
        {
            "Effect": "Allow",
            "Action": [
              "secretsmanager:Get*"
            ],
            "Resource": [
              "arn:aws:secretsmanager:ap-southeast-2:${var.aws_account_id}:secret:/backups/*"
            ],
            "Sid": "GetAnyBackupsSecrets"
        }
      ]
    }
EOF
}


resource "aws_iam_policy" "sns_alerts" {
  name_prefix = "backups-node-sns-alerts"
  policy      = <<-EOF
    {
      "Version": "2012-10-17",
      "Statement": [
        {
            "Effect": "Allow",
            "Action": [
              "sns:Publish"
            ],
            "Resource": [
              "${data.terraform_remote_state.aws_account_misc.outputs.sns_admin_alert_mail_arn}",
              "${data.terraform_remote_state.aws_account_misc.outputs.sns_admin_alert_sms_arn}"
            ],
            "Sid": "SNSAlerts"
        }
      ]
    }
EOF
}

resource "aws_iam_policy" "efs_mounts" {
  name_prefix = "backups-node-efs-mount"
  # elasticfilesystem:ClientMount - readonly (empirical testing shows I can write with this!)
  # elasticfilesystem:ClientWrite - write
  # elasticfilesystem:ClientRootAccess - root user access
  policy = <<-EOF
    {
      "Version": "2012-10-17",
      "Statement": [
        {
            "Effect": "Allow",
            "Action": [
              "elasticfilesystem:ClientWrite",
              "elasticfilesystem:Describe*",
              "elasticfilesystem:List"
              ],
            "Resource": ["*"],
            "Sid": "MountAnyEFS"
        }
      ]
    }
EOF
}

resource "aws_iam_policy" "s3_read_all_write_backups_buckets" {
  count       = var.s3_backup_write_perms ? 1 : 0
  name_prefix = "s3-backups-rw"
  policy      = <<-EOF
    {
        "Version": "2012-10-17",
        "Statement": [
        {
            "Effect": "Allow",
            "Action": ["s3:*"],
            "Resource": [
              "${data.terraform_remote_state.ops_buckets.outputs.backups_bucket_arn}",
              "${data.terraform_remote_state.ops_buckets.outputs.backups_bucket_arn}/*"
              ],
            "Sid": "S3BackupsWrite"
        },
        {
            "Effect": "Allow",
            "Action": [
              "s3:List*",
              "s3:Get*",
              "s3:Head*",
              "s3:Describe*",
              "s3-object-lambda:Get*",
              "s3-object-lambda:List*"
            ],
            "Resource": ["*"],
            "Sid": "S3AllBucketsReadOnly"
        }
      ]
    }
EOF
}

resource "aws_iam_policy" "s3_read_all_buckets" {
  count       = var.s3_backup_write_perms ? 0 : 1
  name_prefix = "s3-all-buckets-readonly"
  policy      = <<-EOF
    {
        "Version": "2012-10-17",
        "Statement": [
        {
            "Effect": "Allow",
            "Action": [
              "s3:List*",
              "s3:Get*",
              "s3:Head*",
              "s3:Describe*",
              "s3-object-lambda:Get*",
              "s3-object-lambda:List*"
            ],
            "Resource": ["*"],
            "Sid": "S3AllBucketsReadOnly"
        }
      ]
    }
EOF
}

##
## Firewall
##

resource "aws_security_group" "ec2_backups_nodes" {
  #name_prefix by default has a picosecond suffix... really guys? 26 chars from YYYY on down...
  name_prefix = "ec2-backups-nodes" # this prefix is selected for by client stacks to allow EFS access

  description = "ec2 nodes to have mutliple client-side-permitted efs access"
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

  lifecycle {
    create_before_destroy = true
  }
}