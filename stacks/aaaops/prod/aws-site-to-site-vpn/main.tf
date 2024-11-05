# pinched from https://awstip.com/aws-site-to-site-vpn-using-terraform-324b61b14cb0
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

data "terraform_remote_state" "aaaops_vpc" {
  backend = "s3"
  config = {
    bucket = "aaa-terraform"
    key    = "aaaops/prod/aws-vpc/terraform.tfstate"
    region = var.aws_region
  }
}

resource "aws_cloudwatch_log_group" "tunnels" {
  name              = "/vpn/${var.customer_gateway_device_name}"
  retention_in_days = 365
}

resource "aws_customer_gateway" "customer_gateway" {
  bgp_asn         = var.customer_gateway_bgp_asn
  ip_address      = var.customer_gateway_ip_address
  type            = var.customer_gateway_type
  device_name     = var.customer_gateway_device_name
  certificate_arn = var.customer_gateway_certificate_arn

  tags = var.tags

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpn_gateway" "virtual_private_gateways" {
  vpc_id            = data.terraform_remote_state.aaaops_vpc.outputs.vpc_id
  amazon_side_asn   = var.virtual_private_gateways_amazon_side_asn
  availability_zone = var.virtual_private_gateways_availability_zone

  tags = var.tags
}

resource "aws_vpn_gateway_route_propagation" "route_propagation" {
  count          = length(data.terraform_remote_state.aaaops_vpc.outputs.private_subnets_cidr_blocks)
  vpn_gateway_id = join("", aws_vpn_gateway.virtual_private_gateways.*.id)
  route_table_id = element(data.terraform_remote_state.aaaops_vpc.outputs.private_route_table_ids, count.index)
}

resource "aws_vpn_connection" "vpn_connection" {
  customer_gateway_id                     = join("", aws_customer_gateway.customer_gateway.*.id)
  vpn_gateway_id                          = var.vpn_connection_transit_gateway_id != null ? null : join("", aws_vpn_gateway.virtual_private_gateways.*.id)
  type                                    = var.customer_gateway_type
  static_routes_only                      = var.vpn_connection_static_routes_only
  local_ipv4_network_cidr                 = var.vpn_connection_local_ipv4_network_cidr
  outside_ip_address_type                 = var.vpn_connection_outside_ip_address_type
  remote_ipv4_network_cidr                = var.vpn_connection_remote_ipv4_network_cidr
  transport_transit_gateway_attachment_id = var.vpn_connection_transport_transit_gateway_attachment_id

  transit_gateway_id       = var.vpn_connection_transit_gateway_id != null ? var.vpn_connection_transit_gateway_id : null
  enable_acceleration      = var.vpn_connection_transit_gateway_id != null ? var.vpn_connection_enable_acceleration : null
  local_ipv6_network_cidr  = var.vpn_connection_transit_gateway_id != null ? var.vpn_connection_local_ipv6_network_cidr : null
  remote_ipv6_network_cidr = var.vpn_connection_transit_gateway_id != null ? var.vpn_connection_remote_ipv6_network_cidr : null
  tunnel1_inside_ipv6_cidr = var.vpn_connection_transit_gateway_id != null ? var.vpn_connection_tunnel1_inside_ipv6_cidr : null
  tunnel2_inside_ipv6_cidr = var.vpn_connection_transit_gateway_id != null ? var.vpn_connection_tunnel2_inside_ipv6_cidr : null

  ###vpn_connection_tunnel
  tunnel_inside_ip_version = var.vpn_connection_tunnel_inside_ip_version

  tunnel1_inside_cidr                  = var.vpn_connection_tunnel1_inside_cidr
  tunnel1_preshared_key                = var.vpn_connection_tunnel1_preshared_key
  tunnel1_dpd_timeout_action           = var.vpn_connection_tunnel1_dpd_timeout_action
  tunnel1_dpd_timeout_seconds          = var.vpn_connection_tunnel1_dpd_timeout_seconds
  tunnel1_ike_versions                 = var.vpn_connection_tunnel1_ike_versions
  tunnel1_phase1_dh_group_numbers      = var.vpn_connection_tunnel1_phase1_dh_group_numbers
  tunnel1_phase1_encryption_algorithms = var.vpn_connection_tunnel1_phase1_encryption_algorithms
  tunnel1_phase1_integrity_algorithms  = var.vpn_connection_tunnel1_phase1_integrity_algorithms
  tunnel1_phase1_lifetime_seconds      = var.vpn_connection_tunnel1_phase1_lifetime_seconds
  tunnel1_phase2_dh_group_numbers      = var.vpn_connection_tunnel1_phase2_dh_group_numbers
  tunnel1_phase2_encryption_algorithms = var.vpn_connection_tunnel1_phase2_encryption_algorithms
  tunnel1_phase2_integrity_algorithms  = var.vpn_connection_tunnel1_phase2_integrity_algorithms
  tunnel1_phase2_lifetime_seconds      = var.vpn_connection_tunnel1_phase2_lifetime_seconds
  tunnel1_rekey_fuzz_percentage        = var.vpn_connection_tunnel1_rekey_fuzz_percentage
  tunnel1_rekey_margin_time_seconds    = var.vpn_connection_tunnel1_rekey_margin_time_seconds
  tunnel1_replay_window_size           = var.vpn_connection_tunnel1_replay_window_size
  tunnel1_startup_action               = var.vpn_connection_tunnel1_startup_action
  tunnel1_log_options {
    dynamic "cloudwatch_log_options" {
      for_each = var.tunnel1_log_options
      content {
        log_enabled = cloudwatch_log_options.value.log_enabled
        #log_group_arn     = cloudwatch_log_options.value.log_group_arn
        log_group_arn     = aws_cloudwatch_log_group.tunnels.arn
        log_output_format = cloudwatch_log_options.value.log_output_format
      }
    }
  }

  tunnel2_inside_cidr                  = var.vpn_connection_tunnel2_inside_cidr
  tunnel2_preshared_key                = var.vpn_connection_tunnel2_preshared_key
  tunnel2_dpd_timeout_action           = var.vpn_connection_tunnel2_dpd_timeout_action
  tunnel2_dpd_timeout_seconds          = var.vpn_connection_tunnel2_dpd_timeout_seconds
  tunnel2_ike_versions                 = var.vpn_connection_tunnel2_ike_versions
  tunnel2_phase1_dh_group_numbers      = var.vpn_connection_tunnel2_phase1_dh_group_numbers
  tunnel2_phase1_encryption_algorithms = var.vpn_connection_tunnel2_phase1_encryption_algorithms
  tunnel2_phase1_integrity_algorithms  = var.vpn_connection_tunnel2_phase1_integrity_algorithms
  tunnel2_phase1_lifetime_seconds      = var.vpn_connection_tunnel2_phase1_lifetime_seconds
  tunnel2_phase2_dh_group_numbers      = var.vpn_connection_tunnel2_phase2_dh_group_numbers
  tunnel2_phase2_encryption_algorithms = var.vpn_connection_tunnel2_phase2_encryption_algorithms
  tunnel2_phase2_integrity_algorithms  = var.vpn_connection_tunnel2_phase2_integrity_algorithms
  tunnel2_phase2_lifetime_seconds      = var.vpn_connection_tunnel2_phase2_lifetime_seconds
  tunnel2_rekey_fuzz_percentage        = var.vpn_connection_tunnel2_rekey_fuzz_percentage
  tunnel2_rekey_margin_time_seconds    = var.vpn_connection_tunnel2_rekey_margin_time_seconds
  tunnel2_replay_window_size           = var.vpn_connection_tunnel2_replay_window_size
  tunnel2_startup_action               = var.vpn_connection_tunnel2_startup_action
  tunnel2_log_options {
    dynamic "cloudwatch_log_options" {
      for_each = var.tunnel2_log_options
      content {
        log_enabled = cloudwatch_log_options.value.log_enabled
        #log_group_arn     = cloudwatch_log_options.value.log_group_arn
        log_group_arn     = aws_cloudwatch_log_group.tunnels.arn
        log_output_format = cloudwatch_log_options.value.log_output_format
      }
    }
  }

  tags = var.tags
}

resource "aws_vpn_connection_route" "vpn_connection_route" {
  count                  = var.virtual_private_gateways_availability_zone == null ? 0 : length(var.vpn_connection_route_destination_cidr_block)
  destination_cidr_block = element(var.vpn_connection_route_destination_cidr_block, count.index)
  vpn_connection_id      = aws_vpn_connection.vpn_connection.id
}