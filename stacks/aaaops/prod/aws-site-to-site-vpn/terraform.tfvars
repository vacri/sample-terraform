customer_gateway_bgp_asn    = 65000
customer_gateway_ip_address = "2.4.6.8" # paul sez: assuming legacy vpn is on same device
customer_gateway_type       = "ipsec.1"       #(Required) The only type AWS supports at this time is ipsec.1
# customer_gateway_certificate_arn = "arn:aws:acm:ap-southeast-1:111111111111:certificate/365ac088-d023-4690-aa8e-6e4831a73332"
customer_gateway_device_name = "aaa-firepower" # paul sez: hope hyphens are okay
tags = {
  "Name" = "aaa-firepower"
}
#virtual_private_gateways_vpc_id = "" # paul sez: use imported var instead
# # virtual_private_gateways_amazon_side_asn = 65001
# virtual_private_gateways_availability_zone = "ap-southeast-1a"
#route_propagation_route_table_ids       = ["rtb-033562682aace18be"]
# paul sez: replace above with data.terraform_remote_state.vpc.outputs.private_subnets_cidr_blocks
virtual_private_gateways_availability_zone = "ap-southeast-2a"

vpn_connection_static_routes_only       = true # Static routes must be used for devices that don't support BGP.
vpn_connection_local_ipv4_network_cidr  = "0.0.0.0/0"
vpn_connection_outside_ip_address_type  = "PublicIpv4"
vpn_connection_remote_ipv4_network_cidr = "0.0.0.0/0"

#####EC2 Transit Gateway
vpn_connection_transit_gateway_id       = null
vpn_connection_local_ipv6_network_cidr  = "::/0"
vpn_connection_remote_ipv6_network_cidr = "::/0"
vpn_connection_tunnel1_inside_ipv6_cidr = "fd00::/126"
vpn_connection_tunnel2_inside_ipv6_cidr = "fd00:1::/126"
vpn_connection_enable_acceleration      = true # Supports only EC2 Transit Gateway.
# vpn_connection_transport_transit_gateway_attachment_id =

##vpn_connection_tunnel
vpn_connection_tunnel_inside_ip_version = "ipv4" # paul sez: ip6 available inside Transit Gateways only (not that we use ip6)
# vpn_connection_tunnel1_inside_cidr = "169.254.253.152/30"
# vpn_connection_tunnel2_inside_cidr = "169.254.116.244/30"
tunnel1_log_options = [{
  log_enabled       = true
  log_group_arn     = "arn:aws:logs:ap-southeast-2:7654321098:log-group:aaa-firepower-vpn-loggroup:*" # paul sez: using a different method in main.tf
  log_output_format = "text"
}]
tunnel2_log_options = [{
  log_enabled       = true
  log_group_arn     = "arn:aws:logs:ap-southeast-2:7654321098:log-group:aaa-firepower-vpn-loggroup:*" # paul sez: using a different method in main.tf
  log_output_format = "json"
}]

vpn_connection_tunnel1_phase1_encryption_algorithms = ["AES128"]
vpn_connection_tunnel1_phase2_encryption_algorithms = ["AES128"]
vpn_connection_tunnel1_ike_versions                 = ["ikev1"]
vpn_connection_tunnel1_rekey_margin_time_seconds    = 60
# vpn_connection_tunnel1_phase1_integrity_algorithms  = ["SHA2-256"]
# vpn_connection_tunnel1_phase2_integrity_algorithms  = ["SHA2-256"]
vpn_connection_tunnel1_phase1_integrity_algorithms = ["SHA1"]
vpn_connection_tunnel1_phase2_integrity_algorithms = ["SHA1"]
vpn_connection_tunnel1_rekey_fuzz_percentage       = 100
vpn_connection_tunnel1_replay_window_size          = 64
vpn_connection_tunnel1_phase1_dh_group_numbers     = [14]
vpn_connection_tunnel1_phase2_dh_group_numbers     = ["14"]
vpn_connection_tunnel1_dpd_timeout_seconds         = 30
vpn_connection_tunnel1_dpd_timeout_action          = "clear"
vpn_connection_tunnel1_phase1_lifetime_seconds     = 1000
vpn_connection_tunnel1_phase2_lifetime_seconds     = 1000
vpn_connection_tunnel1_startup_action              = "add"

vpn_connection_tunnel2_phase1_encryption_algorithms = ["AES128"]
vpn_connection_tunnel2_phase2_encryption_algorithms = ["AES128"]
vpn_connection_tunnel2_ike_versions                 = ["ikev1"]
vpn_connection_tunnel2_rekey_margin_time_seconds    = 60
# vpn_connection_tunnel2_phase1_integrity_algorithms  = ["SHA2-256"]
# vpn_connection_tunnel2_phase2_integrity_algorithms  = ["SHA2-256"]
vpn_connection_tunnel2_phase1_integrity_algorithms = ["SHA1"]
vpn_connection_tunnel2_phase2_integrity_algorithms = ["SHA1"]
vpn_connection_tunnel2_rekey_fuzz_percentage       = 100
vpn_connection_tunnel2_replay_window_size          = 64
vpn_connection_tunnel2_phase1_dh_group_numbers     = [14]
vpn_connection_tunnel2_phase2_dh_group_numbers     = ["14"]
vpn_connection_tunnel2_dpd_timeout_seconds         = 30
vpn_connection_tunnel2_dpd_timeout_action          = "clear"
vpn_connection_tunnel2_phase1_lifetime_seconds     = 1000
vpn_connection_tunnel2_phase2_lifetime_seconds     = 1000
vpn_connection_tunnel2_startup_action              = "add"

# vpn_connection_static_route
#vpn_connection_route_destination_cidr_block = ["192.168.10.0/24", "192.168.20.0/24", "192.168.30.0/24"]
vpn_connection_route_destination_cidr_block = ["10.0.0.0/16", "10.1.0.0/16"]
