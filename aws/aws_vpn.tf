# ============================================================
# AWS Site-to-Site VPN — AWS ↔ GCP Hybrid Connectivity
# ============================================================

variable "gcp_vpn_ip_0" {
  description = "GCP HA-VPN interface 0 public IP"
  type        = string
  default     = "0.0.0.0"
}

variable "gcp_vpn_ip_1" {
  description = "GCP HA-VPN interface 1 public IP"
  type        = string
  default     = "0.0.0.0"
}

variable "vpn_shared_secret" {
  description = "Shared secret for VPN tunnels"
  type        = string
  sensitive   = true
  default     = "SecureVPN_Khadija_2026"
}

# ============================================================
# Virtual Private Gateway (AWS side)
# ============================================================

resource "aws_vpn_gateway" "aws_vgw" {
  vpc_id          = aws_vpc.main.id
  amazon_side_asn = 64512

  tags = {
    Name    = "${var.project_name}-vgw"
    Project = var.project_name
  }
}

resource "aws_vpn_gateway_attachment" "vgw_attach" {
  vpc_id         = aws_vpc.main.id
  vpn_gateway_id = aws_vpn_gateway.aws_vgw.id
}

# ============================================================
# Customer Gateways (GCP HA-VPN interfaces)
# ============================================================

resource "aws_customer_gateway" "gcp_cgw_0" {
  bgp_asn    = 64514
  ip_address = var.gcp_vpn_ip_0
  type       = "ipsec.1"

  tags = {
    Name    = "gcp-cgw-interface-0"
    Project = var.project_name
  }
}

resource "aws_customer_gateway" "gcp_cgw_1" {
  bgp_asn    = 64514
  ip_address = var.gcp_vpn_ip_1
  type       = "ipsec.1"

  tags = {
    Name    = "gcp-cgw-interface-1"
    Project = var.project_name
  }
}

# ============================================================
# Site-to-Site VPN Connections
# NOTE: AWS interdit les ranges 169.254.0.0/30 à 169.254.5.0/30
#       On utilise 169.254.10.x – 169.254.13.x
#       Ces ranges DOIVENT correspondre aux ip_range dans gcp_vpn_complete.tf
# ============================================================

resource "aws_vpn_connection" "aws_to_gcp_0" {
  vpn_gateway_id      = aws_vpn_gateway.aws_vgw.id
  customer_gateway_id = aws_customer_gateway.gcp_cgw_0.id
  type                = "ipsec.1"
  static_routes_only  = false

  tunnel1_preshared_key = var.vpn_shared_secret
  tunnel2_preshared_key = var.vpn_shared_secret
  tunnel1_inside_cidr   = "169.254.10.0/30"
  tunnel2_inside_cidr   = "169.254.11.0/30"

  tags = {
    Name    = "${var.project_name}-vpn-tunnel-0"
    Project = var.project_name
  }
}

resource "aws_vpn_connection" "aws_to_gcp_1" {
  vpn_gateway_id      = aws_vpn_gateway.aws_vgw.id
  customer_gateway_id = aws_customer_gateway.gcp_cgw_1.id
  type                = "ipsec.1"
  static_routes_only  = false

  tunnel1_preshared_key = var.vpn_shared_secret
  tunnel2_preshared_key = var.vpn_shared_secret
  tunnel1_inside_cidr   = "169.254.12.0/30"
  tunnel2_inside_cidr   = "169.254.13.0/30"

  tags = {
    Name    = "${var.project_name}-vpn-tunnel-1"
    Project = var.project_name
  }
}

# ============================================================
# Route propagation for VPN in private subnet
# ============================================================

resource "aws_vpn_gateway_route_propagation" "private_rt_propagation" {
  vpn_gateway_id = aws_vpn_gateway.aws_vgw.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name    = "${var.project_name}-private-rt"
    Project = var.project_name
  }
}

resource "aws_route_table_association" "private_assoc" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private_rt.id
}

# ============================================================
# Outputs
# ============================================================

output "aws_vgw_id" {
  value       = aws_vpn_gateway.aws_vgw.id
  description = "AWS Virtual Gateway ID"
}

output "aws_vpn_tunnel0_outside_ip" {
  value       = aws_vpn_connection.aws_to_gcp_0.tunnel1_address
  description = "AWS VPN Tunnel 0 outside IP (configure in GCP)"
}

output "aws_vpn_tunnel1_outside_ip" {
  value       = aws_vpn_connection.aws_to_gcp_0.tunnel2_address
  description = "AWS VPN Tunnel 1 outside IP (configure in GCP)"
}
