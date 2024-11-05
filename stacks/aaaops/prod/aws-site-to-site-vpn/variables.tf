variable "customer_gateway_bgp_asn" {
  description = "The ASN of your customer gateway device. The Border Gateway Protocol (BGP) Autonomous System Number (ASN) in the range of 1 – 2,147,483,647 is supported."
  type        = number
}
variable "customer_gateway_ip_address" {
  description = "Specify the internet-routable IP address for your gateway's external interface; the address must be static and may be behind a device performing network address translation (NAT)."
  type        = string
  default     = null
}
variable "customer_gateway_type" {
  description = "(Required) The type of customer gateway. The only type AWS supports at this time is \"ipsec.1\"."
  type        = string
}
variable "customer_gateway_device_name" {
  description = "(Optional) Enter a name for the customer gateway device."
  type        = string
  default     = null
}
variable "customer_gateway_certificate_arn" {
  description = "(Optional) The ARN of a private certificate provisioned in AWS Certificate Manager (ACM)."
  type        = string
  default     = null
}
variable "tags" {
  description = "common tags for vpn resources."
  type        = map(string)
}

/*virtual_private_gateways*/
#replaced with data.terraform_remote_state.aaaops_vpc.outputs.vpc_id
# variable "virtual_private_gateways_vpc_id" {
#   description = "(Required) A create a virtual private gateway, you must attach it to your VPC"
#   type        = string
# }
variable "virtual_private_gateways_amazon_side_asn" {
  description = "(Optional) The Autonomous System Number (ASN) for the Amazon side of the gateway. If you don't specify an ASN, the virtual private gateway is created with the default ASN."
  type        = number
  default     = null
}
variable "virtual_private_gateways_availability_zone" {
  description = "(Optional) The Availability Zone for the virtual private gateway."
  type        = string
  default     = null
}
variable "vpn_connection_transit_gateway_id" {
  description = "(Optional) The ID of the EC2 Transit Gateway."
  type        = string
  default     = null
}
/*Route propagation*/
variable "route_propagation_route_table_ids" {
  description = "(Optional)The IDs of the route tables for which routes from the Virtual Private Gateway will be propagated"
  type        = list(string)
  default     = []
}
variable "vpn_connection_static_routes_only" {
  description = "(Optional, Default false) Whether the VPN connection uses static routes exclusively. Static routes must be used for devices that don't support BGP."
  type        = bool
  default     = false
}
variable "vpn_connection_enable_acceleration" {
  description = "(Optional, Default false) Indicate whether to enable acceleration for the VPN connection. Supports only EC2 Transit Gateway."
  type        = bool
  default     = false
}
variable "vpn_connection_local_ipv4_network_cidr" {
  description = "(Optional, Default 0.0.0.0/0) The IPv4 CIDR on the customer gateway (on-premises) side of the VPN connection."
  type        = string
  default     = null
}
variable "vpn_connection_local_ipv6_network_cidr" {
  description = "(Optional, Default ::/0) The IPv6 CIDR on the customer gateway (on-premises) side of the VPN connection."
  type        = string
  default     = null
}
variable "vpn_connection_outside_ip_address_type" {
  description = "(Optional, Default PublicIpv4) Indicates if a Public S2S VPN or Private S2S VPN over AWS Direct Connect. Valid values are PublicIpv4 | PrivateIpv4"
  type        = string
  default     = null
  validation {
    condition     = can(regex("^(PublicIpv4|PrivateIpv4)$", var.vpn_connection_outside_ip_address_type))
    error_message = "Invalid input, options: \"PublicIpv4\", \"PrivateIpv4\"."
  }
}
variable "vpn_connection_remote_ipv4_network_cidr" {
  description = "(Optional, Default 0.0.0.0/0) The IPv4 CIDR on the AWS side of the VPN connection."
  type        = string
  default     = null
}
variable "vpn_connection_remote_ipv6_network_cidr" {
  description = "(Optional, Default ::/0) The IPv6 CIDR on the customer gateway (on-premises) side of the VPN connection."
  type        = string
  default     = null
}
variable "vpn_connection_transport_transit_gateway_attachment_id" {
  description = "(Required when outside_ip_address_type is set to PrivateIpv4). The attachment ID of the Transit Gateway attachment to Direct Connect Gateway. The ID is obtained through a data source only."
  type        = string
  default     = null
}
##vpn_connection_tunnel
variable "vpn_connection_tunnel_inside_ip_version" {
  description = "(Optional, Default ipv4) Indicate whether the VPN tunnels process IPv4 or IPv6 traffic. Valid values are ipv4 | ipv6. ipv6 Supports only EC2 Transit Gateway."
  type        = string
  default     = null
  validation {
    condition     = can(regex("^(ipv4|ipv6)$", var.vpn_connection_tunnel_inside_ip_version))
    error_message = "Invalid input, options: \"ipv4\", \"ipv6\"."
  }
}
variable "vpn_connection_tunnel1_inside_cidr" {
  description = " (Optional) The CIDR block of the inside IP addresses for the first VPN tunnel. Valid value is a size /30 CIDR block from the 169.254.0.0/16 range."
  type        = string
  default     = null
}
variable "vpn_connection_tunnel2_inside_cidr" {
  description = "(Optional) The CIDR block of the inside IP addresses for the second VPN tunnel. Valid value is a size /30 CIDR block from the 169.254.0.0/16 range."
  type        = string
  default     = null
}
variable "vpn_connection_tunnel1_inside_ipv6_cidr" {
  description = "(Optional) The range of inside IPv6 addresses for the first VPN tunnel. Supports only EC2 Transit Gateway. Valid value is a size /126 CIDR block from the local fd00::/8 range."
  type        = string
  default     = null
}
variable "vpn_connection_tunnel2_inside_ipv6_cidr" {
  description = "(Optional) The range of inside IPv6 addresses for the second VPN tunnel. Supports only EC2 Transit Gateway. Valid value is a size /126 CIDR block from the local fd00::/8 range."
  type        = string
  default     = null
}
variable "vpn_connection_tunnel1_preshared_key" {
  description = "(Optional) The preshared key of the first VPN tunnel. The preshared key must be between 8 and 64 characters in length and cannot start with zero(0). Allowed characters are alphanumeric characters, periods(.) and underscores(_)."
  type        = string
  default     = null
  sensitive   = true
}
variable "vpn_connection_tunnel2_preshared_key" {
  description = " (Optional) The preshared key of the second VPN tunnel. The preshared key must be between 8 and 64 characters in length and cannot start with zero(0). Allowed characters are alphanumeric characters, periods(.) and underscores(_)."
  type        = string
  default     = null
  sensitive   = true
}
variable "vpn_connection_tunnel1_dpd_timeout_action" {
  description = "(Optional, Default clear) The action to take after DPD timeout occurs for the first VPN tunnel. Specify restart to restart the IKE initiation. Specify clear to end the IKE session. Valid values are clear | none | restart."
  type        = string
  default     = "clear"
  validation {
    condition     = can(regex("^(clear|none|restart)$", var.vpn_connection_tunnel1_dpd_timeout_action))
    error_message = "Invalid input, options: \"clear\", \"none\", \"restart\"."
  }
}
variable "vpn_connection_tunnel2_dpd_timeout_action" {
  description = "(Optional, Default clear) The action to take after DPD timeout occurs for the second VPN tunnel. Specify restart to restart the IKE initiation. Specify clear to end the IKE session. Valid values are clear | none | restart."
  type        = string
  default     = "clear"
  validation {
    condition     = can(regex("^(clear|none|restart)$", var.vpn_connection_tunnel2_dpd_timeout_action))
    error_message = "Invalid input, options: \"clear\", \"none\", \"restart\"."
  }
}
variable "vpn_connection_tunnel1_dpd_timeout_seconds" {
  description = "(Optional, Default 30) The number of seconds after which a DPD timeout occurs for the second VPN tunnel. Valid value is equal or higher than 30."
  type        = number
  default     = 30
}
variable "vpn_connection_tunnel2_dpd_timeout_seconds" {
  description = "(Optional, Default 30) The number of seconds after which a DPD timeout occurs for the second VPN tunnel. Valid value is equal or higher than 30."
  type        = string
  default     = 30
}
variable "vpn_connection_tunnel1_ike_versions" {
  description = "(Optional) The IKE versions that are permitted for the first VPN tunnel. Valid values are ikev1 | ikev2."
  type        = set(string)
  default     = [null]
  validation {
    condition     = can([for i in var.vpn_connection_tunnel1_ike_versions : regex("^(ikev1|ikev2)$", i)])
    error_message = "Invalid input, options: \"ikev1\",\"ikev2\"."
  }
}
variable "vpn_connection_tunnel2_ike_versions" {
  description = "(Optional) The IKE versions that are permitted for the first VPN tunnel. Valid values are ikev1 | ikev2."
  type        = set(string)
  default     = [null]
  validation {
    condition     = can([for i in var.vpn_connection_tunnel2_ike_versions : regex("^(ikev1|ikev2)$", i)])
    error_message = "Invalid input, options: \"ikev1\",\"ikev2\"."
  }
}
variable "tunnel1_log_options" {
  description = "(Optional) Options for logging VPN tunnel activity. "
  type = list(object({
    log_enabled       = bool   # (Optional) Enable or disable VPN tunnel logging feature. The default is false.
    log_group_arn     = string # (Optional) The Amazon Resource Name (ARN) of the CloudWatch log group to send logs to.
    log_output_format = string # (Optional) Set log format. Default format is json. Possible values are: json and text. The default is json.
  }))
  default = []
  validation {
    condition     = can(regex("^(json|text)$", var.tunnel1_log_options[0].log_output_format))
    error_message = "Invalid input, options: \"json\",\"text\"."
  }
}
variable "tunnel2_log_options" {
  description = "(Optional) Options for logging VPN tunnel activity. "
  type = list(object({
    log_enabled       = bool   # (Optional) Enable or disable VPN tunnel logging feature. The default is false.
    log_group_arn     = string # (Optional) The Amazon Resource Name (ARN) of the CloudWatch log group to send logs to.
    log_output_format = string # (Optional) Set log format. Default format is json. Possible values are: json and text. The default is json.
  }))
  default = []
  validation {
    condition     = can(regex("^(json|text)$", var.tunnel2_log_options[0].log_output_format))
    error_message = "Invalid input, options: \"json\",\"text\"."
  }
}
variable "vpn_connection_tunnel1_phase1_dh_group_numbers" {
  description = "(Optional) List of one or more Diffie-Hellman group numbers that are permitted for the first VPN tunnel for phase 1 IKE negotiations. Valid values are 2 | 14 | 15 | 16 | 17 | 18 | 19 | 20 | 21 | 22 | 23 | 24."
  type        = set(number)
  default     = [2, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24]
  validation {
    condition     = can([for i in var.vpn_connection_tunnel1_phase1_dh_group_numbers : regex("^(2|14|15|16|17|18|19|20|21|22|23|24)$", i)])
    error_message = "Invalid input, options: \"2|14|15|16|17|18|19|20|21|22|23|24\"."
  }
}
variable "vpn_connection_tunnel2_phase1_dh_group_numbers" {
  description = "(Optional) List of one or more Diffie-Hellman group numbers that are permitted for the second VPN tunnel for phase 1 IKE negotiations. Valid values are 2 | 14 | 15 | 16 | 17 | 18 | 19 | 20 | 21 | 22 | 23 | 24."
  type        = set(number)
  default     = [2, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24]
  validation {
    condition     = can([for i in var.vpn_connection_tunnel2_phase1_dh_group_numbers : regex("^(2|14|15|16|17|18|19|20|21|22|23|24)$", i)])
    error_message = "Invalid input, options: \"2|14|15|16|17|18|19|20|21|22|23|24\"."
  }
}
variable "vpn_connection_tunnel1_phase1_encryption_algorithms" {
  description = "(Optional) List of one or more encryption algorithms that are permitted for the first VPN tunnel for phase 1 IKE negotiations. Valid values are AES128 | AES256 | AES128-GCM-16 | AES256-GCM-16."
  type        = set(string)
  default     = ["AES128", "AES256", "AES128-GCM-16", "AES256-GCM-16"]
  validation {
    condition     = can([for i in var.vpn_connection_tunnel1_phase1_encryption_algorithms : regex("^(AES128|AES256|AES128-GCM-16|AES256-GCM-16)$", i)])
    error_message = "Invalid input, options: \"AES128|AES256|AES128-GCM-16|AES256-GCM-16\"."
  }
}
variable "vpn_connection_tunnel2_phase1_encryption_algorithms" {
  description = "(Optional) List of one or more encryption algorithms that are permitted for the second VPN tunnel for phase 1 IKE negotiations. Valid values are AES128 | AES256 | AES128-GCM-16 | AES256-GCM-16."
  type        = set(string)
  default     = ["AES128", "AES256", "AES128-GCM-16", "AES256-GCM-16"]
  validation {
    condition     = can([for i in var.vpn_connection_tunnel2_phase1_encryption_algorithms : regex("^(AES128|AES256|AES128-GCM-16|AES256-GCM-16)$", i)])
    error_message = "Invalid input, options: \"AES128|AES256|AES128-GCM-16|AES256-GCM-16\"."
  }
}
variable "vpn_connection_tunnel1_phase1_integrity_algorithms" {
  description = "(Optional) One or more integrity algorithms that are permitted for the first VPN tunnel for phase 1 IKE negotiations. Valid values are SHA1 | SHA2-256 | SHA2-384 | SHA2-512."
  type        = set(string)
  default     = ["SHA1", "SHA2-256", "SHA2-384", "SHA2-512"]
  validation {
    condition     = can([for i in var.vpn_connection_tunnel1_phase1_integrity_algorithms : regex("^(SHA1|SHA2-256|SHA2-384|SHA2-512)$", i)])
    error_message = "Invalid input, options: \"SHA1|SHA2-256|SHA2-384|SHA2-512\"."
  }
}
variable "vpn_connection_tunnel2_phase1_integrity_algorithms" {
  description = "(Optional) One or more integrity algorithms that are permitted for the second VPN tunnel for phase 1 IKE negotiations. Valid values are SHA1 | SHA2-256 | SHA2-384 | SHA2-512."
  type        = set(string)
  default     = ["SHA1", "SHA2-256", "SHA2-384", "SHA2-512"]
  validation {
    condition     = can([for i in var.vpn_connection_tunnel2_phase1_integrity_algorithms : regex("^(SHA1|SHA2-256|SHA2-384|SHA2-512)$", i)])
    error_message = "Invalid input, options: \"SHA1|SHA2-256|SHA2-384|SHA2-512\"."
  }
}
variable "vpn_connection_tunnel1_phase1_lifetime_seconds" {
  description = " (Optional, Default 28800) The lifetime for phase 1 of the IKE negotiation for the first VPN tunnel, in seconds. Valid value is between 900 and 28800."
  type        = number
  default     = 28800
  validation {
    condition     = var.vpn_connection_tunnel1_phase1_lifetime_seconds <= 28800 && var.vpn_connection_tunnel1_phase1_lifetime_seconds >= 900
    error_message = "Invalid input, options: Valid value is between 900 and 28800."
  }
}
variable "vpn_connection_tunnel2_phase1_lifetime_seconds" {
  description = "(Optional, Default 28800) The lifetime for phase 1 of the IKE negotiation for the second VPN tunnel, in seconds. Valid value is between 900 and 28800."
  type        = number
  default     = 28800
  validation {
    condition     = var.vpn_connection_tunnel2_phase1_lifetime_seconds <= 28800 && var.vpn_connection_tunnel2_phase1_lifetime_seconds >= 900
    error_message = "Invalid input, options: Valid value is between 900 and 28800."
  }
}
variable "vpn_connection_tunnel2_phase2_dh_group_numbers" {
  description = "(Optional) List of one or more Diffie-Hellman group numbers that are permitted for the second VPN tunnel for phase 2 IKE negotiations. Valid values are 2 | 5 | 14 | 15 | 16 | 17 | 18 | 19 | 20 | 21 | 22 | 23 | 24."
  type        = set(number)
  default     = [2, 5, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24]
  validation {
    condition     = can([for i in var.vpn_connection_tunnel2_phase2_dh_group_numbers : regex("^(2|5|14|15|16|17|18|19|20|21|22|23|24)$", i)])
    error_message = "Invalid input, options: \"2|5|14|15|16|17|18|19|20|21|22|23|24\"."
  }
}
variable "vpn_connection_tunnel1_phase2_dh_group_numbers" {
  description = "(Optional) List of one or more Diffie-Hellman group numbers that are permitted for the first VPN tunnel for phase 2 IKE negotiations. Valid values are 2 | 5 | 14 | 15 | 16 | 17 | 18 | 19 | 20 | 21 | 22 | 23 | 24."
  type        = set(number)
  default     = [2, 5, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24]
  validation {
    condition     = can([for i in var.vpn_connection_tunnel1_phase2_dh_group_numbers : regex("^(2|5|14|15|16|17|18|19|20|21|22|23|24)$", i)])
    error_message = "Invalid input, options: \"2|5|14|15|16|17|18|19|20|21|22|23|24\"."
  }
}
variable "vpn_connection_tunnel1_phase2_encryption_algorithms" {
  description = " (Optional) List of one or more encryption algorithms that are permitted for the first VPN tunnel for phase 2 IKE negotiations. Valid values are AES128 | AES256 | AES128-GCM-16 | AES256-GCM-16."
  type        = list(string)
  default     = ["AES128", "AES256", "AES128-GCM-16", "AES256-GCM-16"]
  validation {
    condition     = can([for i in var.vpn_connection_tunnel1_phase2_encryption_algorithms : regex("^(AES128|AES256|AES128-GCM-16|AES256-GCM-16)$", i)])
    error_message = "Invalid input, options: \"AES128|AES256|AES128-GCM-16|AES256-GCM-16\"."
  }
}
variable "vpn_connection_tunnel2_phase2_encryption_algorithms" {
  description = "(Optional) List of one or more encryption algorithms that are permitted for the second VPN tunnel for phase 2 IKE negotiations. Valid values are AES128 | AES256 | AES128-GCM-16 | AES256-GCM-16."
  type        = list(string)
  default     = ["AES128", "AES256", "AES128-GCM-16", "AES256-GCM-16"]
  validation {
    condition     = can([for i in var.vpn_connection_tunnel2_phase2_encryption_algorithms : regex("^(AES128|AES256|AES128-GCM-16|AES256-GCM-16)$", i)])
    error_message = "Invalid input, options: \"AES128|AES256|AES128-GCM-16|AES256-GCM-16\"."
  }
}
variable "vpn_connection_tunnel1_phase2_integrity_algorithms" {
  description = "(Optional) List of one or more integrity algorithms that are permitted for the first VPN tunnel for phase 2 IKE negotiations. Valid values are SHA1 | SHA2-256 | SHA2-384 | SHA2-512."
  type        = list(string)
  default     = ["SHA1", "SHA2-256", "SHA2-384", "SHA2-512"]
  validation {
    condition     = can([for i in var.vpn_connection_tunnel1_phase2_integrity_algorithms : regex("^(SHA1|SHA2-256|SHA2-384|SHA2-512)$", i)])
    error_message = "Invalid input, options: \"SHA1|SHA2-256|SHA2-384|SHA2-512\"."
  }
}
variable "vpn_connection_tunnel2_phase2_integrity_algorithms" {
  description = "(Optional) List of one or more integrity algorithms that are permitted for the second VPN tunnel for phase 2 IKE negotiations. Valid values are SHA1 | SHA2-256 | SHA2-384 | SHA2-512."
  type        = list(string)
  default     = ["SHA1", "SHA2-256", "SHA2-384", "SHA2-512"]
  validation {
    condition     = can([for i in var.vpn_connection_tunnel2_phase2_integrity_algorithms : regex("^(SHA1|SHA2-256|SHA2-384|SHA2-512)$", i)])
    error_message = "Invalid input, options: \"SHA1|SHA2-256|SHA2-384|SHA2-512\"."
  }
}
variable "vpn_connection_tunnel1_phase2_lifetime_seconds" {
  description = " (Optional, Default 3600) The lifetime for phase 2 of the IKE negotiation for the first VPN tunnel, in seconds. Valid value is between 900 and 3600."
  type        = number
  default     = 3600
  validation {
    condition     = var.vpn_connection_tunnel1_phase2_lifetime_seconds <= 3600 && var.vpn_connection_tunnel1_phase2_lifetime_seconds >= 900 || var.vpn_connection_tunnel1_phase2_lifetime_seconds == null
    error_message = "Invalid input, options: Valid value is between 900 and 3600."
  }
}
variable "vpn_connection_tunnel2_phase2_lifetime_seconds" {
  description = "(Optional, Default 3600) The lifetime for phase 2 of the IKE negotiation for the second VPN tunnel, in seconds. Valid value is between 900 and 3600."
  type        = number
  default     = 3600
  validation {
    condition     = var.vpn_connection_tunnel2_phase2_lifetime_seconds <= 3600 && var.vpn_connection_tunnel2_phase2_lifetime_seconds >= 900 || var.vpn_connection_tunnel2_phase2_lifetime_seconds == null
    error_message = "Invalid input, options: Valid value is between 900 and 3600."
  }
}
variable "vpn_connection_tunnel1_rekey_fuzz_percentage" {
  description = "(Optional, Default 100) The percentage of the rekey window for the first VPN tunnel (determined by tunnel1_rekey_margin_time_seconds) during which the rekey time is randomly selected. Valid value is between 0 and 100."
  type        = number
  default     = 100
  validation {
    condition     = var.vpn_connection_tunnel1_rekey_fuzz_percentage <= 100 && var.vpn_connection_tunnel1_rekey_fuzz_percentage >= 0
    error_message = "Invalid input, options: Valid value is between 0 and 100."
  }
}
variable "vpn_connection_tunnel2_rekey_fuzz_percentage" {
  description = "(Optional, Default 100) The percentage of the rekey window for the second VPN tunnel (determined by tunnel2_rekey_margin_time_seconds) during which the rekey time is randomly selected. Valid value is between 0 and 100."
  type        = number
  default     = 100
  validation {
    condition     = var.vpn_connection_tunnel2_rekey_fuzz_percentage <= 100 && var.vpn_connection_tunnel2_rekey_fuzz_percentage >= 0
    error_message = "Invalid input, options: Valid value is between 0 and 100."
  }
}
variable "vpn_connection_tunnel1_rekey_margin_time_seconds" {
  description = "(Optional, Default 540) The margin time, in seconds, before the phase 2 lifetime expires, during which the AWS side of the first VPN connection performs an IKE rekey. The exact time of the rekey is randomly selected based on the value for tunnel1_rekey_fuzz_percentage. Valid value is between 60 and half of tunnel1_phase2_lifetime_seconds."
  type        = number
  default     = 540
}
variable "vpn_connection_tunnel2_rekey_margin_time_seconds" {
  description = "(Optional, Default 540) The margin time, in seconds, before the phase 2 lifetime expires, during which the AWS side of the second VPN connection performs an IKE rekey. The exact time of the rekey is randomly selected based on the value for tunnel2_rekey_fuzz_percentage. Valid value is between 60 and half of tunnel2_phase2_lifetime_seconds."
  type        = number
  default     = 540
}
variable "vpn_connection_tunnel1_replay_window_size" {
  description = "(Optional, Default 1024) The number of packets in an IKE replay window for the first VPN tunnel. Valid value is between 64 and 2048."
  type        = number
  default     = 1024
  validation {
    condition     = var.vpn_connection_tunnel1_replay_window_size <= 2048 && var.vpn_connection_tunnel1_replay_window_size >= 64
    error_message = "Invalid input, options:  Valid value is between 64 and 2048."
  }
}
variable "vpn_connection_tunnel2_replay_window_size" {
  description = "(Optional, Default 1024) The number of packets in an IKE replay window for the second VPN tunnel. Valid value is between 64 and 2048."
  type        = number
  default     = 1024
  validation {
    condition     = var.vpn_connection_tunnel2_replay_window_size <= 2048 && var.vpn_connection_tunnel2_replay_window_size >= 64
    error_message = "Invalid input, options:  Valid value is between 64 and 2048."
  }
}
variable "vpn_connection_tunnel1_startup_action" {
  description = "(Optional, Default add) The action to take when the establishing the tunnel for the first VPN connection. By default, your customer gateway device must initiate the IKE negotiation and bring up the tunnel. Specify start for AWS to initiate the IKE negotiation. Valid values are add | start."
  type        = string
  validation {
    condition     = can(regex("^(add|start)$", var.vpn_connection_tunnel1_startup_action))
    error_message = "Invalid input, options: \"add|start\"."
  }
}
variable "vpn_connection_tunnel2_startup_action" {
  description = "(Optional, Default add) The action to take when the establishing the tunnel for the second VPN connection. By default, your customer gateway device must initiate the IKE negotiation and bring up the tunnel. Specify start for AWS to initiate the IKE negotiation. Valid values are add | start."
  type        = string
  validation {
    condition     = can(regex("^(add|start)$", var.vpn_connection_tunnel2_startup_action))
    error_message = "Invalid input, options: \"add|start\"."
  }
}

variable "vpn_connection_route_destination_cidr_block" {
  description = "(Required) The CIDR block associated with the local subnet of the customer network."
  type        = list(string)
}