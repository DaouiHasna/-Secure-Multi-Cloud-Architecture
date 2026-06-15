# ============================================================
# GCP HA-VPN — Complete Configuration for AWS ↔ GCP Tunnel
# FOUR_IPS_REDUNDANCY : 2 AWS connections × 2 tunnels = 4 IPs
#
# Mapping des IPs :
#   ext iface 0 = 34.251.114.192  (aws_to_gcp_0 tun1)
#   ext iface 1 = 52.31.218.192   (aws_to_gcp_0 tun2)
#   ext iface 2 = 52.208.254.153  (aws_to_gcp_1 tun1)
#   ext iface 3 = 108.132.61.245  (aws_to_gcp_1 tun2)
#
# AWS VGW prend toujours le .1 du /30
# GCP Cloud Router prend le .2 du /30
# ============================================================

variable "aws_vpn_ip_0" {
  description = "AWS VPN connection 0 tunnel 1 outside IP"
  type        = string
  default     = "0.0.0.0"
}

variable "aws_vpn_ip_1" {
  description = "AWS VPN connection 0 tunnel 2 outside IP"
  type        = string
  default     = "0.0.0.0"
}

variable "aws_vpn_ip_2" {
  description = "AWS VPN connection 1 tunnel 1 outside IP"
  type        = string
  default     = "0.0.0.0"
}

variable "aws_vpn_ip_3" {
  description = "AWS VPN connection 1 tunnel 2 outside IP"
  type        = string
  default     = "0.0.0.0"
}

variable "vpn_shared_secret" {
  description = "VPN shared secret (must match AWS)"
  type        = string
  sensitive   = true
  default     = "SecureVPN_Khadija_2026"
}

# ============================================================
# Cloud Router with BGP
# ============================================================

resource "google_compute_router" "gcp_router" {
  name    = "gcp-cloud-router"
  network = google_compute_network.secure_vpc.name
  region  = var.region

  bgp {
    asn                = 64514
    advertise_mode     = "DEFAULT"
    keepalive_interval = 20
  }
}

# ============================================================
# HA VPN Gateway (2 interfaces)
# ============================================================

resource "google_compute_ha_vpn_gateway" "gcp_ha_vpn" {
  name    = "gcp-ha-vpn"
  network = google_compute_network.secure_vpc.id
  region  = var.region
}

# ============================================================
# External VPN Gateway — FOUR_IPS_REDUNDANCY
# ============================================================

resource "google_compute_external_vpn_gateway" "aws_gateway" {
  name            = "aws-external-gateway"
  redundancy_type = "FOUR_IPS_REDUNDANCY"
  description     = "AWS Virtual Private Gateway — 4 tunnel IPs"

  interface {
    id         = 0
    ip_address = var.aws_vpn_ip_0
  }

  interface {
    id         = 1
    ip_address = var.aws_vpn_ip_1
  }

  interface {
    id         = 2
    ip_address = var.aws_vpn_ip_2
  }

  interface {
    id         = 3
    ip_address = var.aws_vpn_ip_3
  }
}

# ============================================================
# VPN Tunnels (4 total)
#   tunnel_gcp0_aws0 : GCP iface 0 → ext iface 0 (34.251.114.192)
#   tunnel_gcp0_aws1 : GCP iface 0 → ext iface 1 (52.31.218.192)
#   tunnel_gcp1_aws0 : GCP iface 1 → ext iface 2 (52.208.254.153)
#   tunnel_gcp1_aws1 : GCP iface 1 → ext iface 3 (108.132.61.245)
# ============================================================

resource "google_compute_vpn_tunnel" "tunnel_gcp0_aws0" {
  name                            = "tunnel-gcp0-aws0"
  region                          = var.region
  vpn_gateway                     = google_compute_ha_vpn_gateway.gcp_ha_vpn.id
  vpn_gateway_interface           = 0
  peer_external_gateway           = google_compute_external_vpn_gateway.aws_gateway.id
  peer_external_gateway_interface = 0
  shared_secret                   = var.vpn_shared_secret
  router                          = google_compute_router.gcp_router.id
  ike_version                     = 2
}

resource "google_compute_vpn_tunnel" "tunnel_gcp0_aws1" {
  name                            = "tunnel-gcp0-aws1"
  region                          = var.region
  vpn_gateway                     = google_compute_ha_vpn_gateway.gcp_ha_vpn.id
  vpn_gateway_interface           = 0
  peer_external_gateway           = google_compute_external_vpn_gateway.aws_gateway.id
  peer_external_gateway_interface = 1
  shared_secret                   = var.vpn_shared_secret
  router                          = google_compute_router.gcp_router.id
  ike_version                     = 2
}

resource "google_compute_vpn_tunnel" "tunnel_gcp1_aws0" {
  name                            = "tunnel-gcp1-aws0"
  region                          = var.region
  vpn_gateway                     = google_compute_ha_vpn_gateway.gcp_ha_vpn.id
  vpn_gateway_interface           = 1
  peer_external_gateway           = google_compute_external_vpn_gateway.aws_gateway.id
  peer_external_gateway_interface = 2
  shared_secret                   = var.vpn_shared_secret
  router                          = google_compute_router.gcp_router.id
  ike_version                     = 2
}

resource "google_compute_vpn_tunnel" "tunnel_gcp1_aws1" {
  name                            = "tunnel-gcp1-aws1"
  region                          = var.region
  vpn_gateway                     = google_compute_ha_vpn_gateway.gcp_ha_vpn.id
  vpn_gateway_interface           = 1
  peer_external_gateway           = google_compute_external_vpn_gateway.aws_gateway.id
  peer_external_gateway_interface = 3
  shared_secret                   = var.vpn_shared_secret
  router                          = google_compute_router.gcp_router.id
  ike_version                     = 2
}

# ============================================================
# BGP Interfaces & Peers
#   AWS VGW = .1 (assigné automatiquement par AWS)
#   GCP Cloud Router = .2
# ============================================================

resource "google_compute_router_interface" "if_gcp0_aws0" {
  name       = "if-gcp0-aws0"
  router     = google_compute_router.gcp_router.name
  region     = var.region
  ip_range   = "169.254.10.2/30"
  vpn_tunnel = google_compute_vpn_tunnel.tunnel_gcp0_aws0.name
}

resource "google_compute_router_peer" "peer_gcp0_aws0" {
  name                      = "peer-gcp0-aws0"
  router                    = google_compute_router.gcp_router.name
  region                    = var.region
  peer_ip_address           = "169.254.10.1"
  peer_asn                  = 64512
  advertised_route_priority = 100
  interface                 = google_compute_router_interface.if_gcp0_aws0.name
}

resource "google_compute_router_interface" "if_gcp0_aws1" {
  name       = "if-gcp0-aws1"
  router     = google_compute_router.gcp_router.name
  region     = var.region
  ip_range   = "169.254.11.2/30"
  vpn_tunnel = google_compute_vpn_tunnel.tunnel_gcp0_aws1.name
}

resource "google_compute_router_peer" "peer_gcp0_aws1" {
  name                      = "peer-gcp0-aws1"
  router                    = google_compute_router.gcp_router.name
  region                    = var.region
  peer_ip_address           = "169.254.11.1"
  peer_asn                  = 64512
  advertised_route_priority = 100
  interface                 = google_compute_router_interface.if_gcp0_aws1.name
}

resource "google_compute_router_interface" "if_gcp1_aws0" {
  name       = "if-gcp1-aws0"
  router     = google_compute_router.gcp_router.name
  region     = var.region
  ip_range   = "169.254.12.2/30"
  vpn_tunnel = google_compute_vpn_tunnel.tunnel_gcp1_aws0.name
}

resource "google_compute_router_peer" "peer_gcp1_aws0" {
  name                      = "peer-gcp1-aws0"
  router                    = google_compute_router.gcp_router.name
  region                    = var.region
  peer_ip_address           = "169.254.12.1"
  peer_asn                  = 64512
  advertised_route_priority = 100
  interface                 = google_compute_router_interface.if_gcp1_aws0.name
}

resource "google_compute_router_interface" "if_gcp1_aws1" {
  name       = "if-gcp1-aws1"
  router     = google_compute_router.gcp_router.name
  region     = var.region
  ip_range   = "169.254.13.2/30"
  vpn_tunnel = google_compute_vpn_tunnel.tunnel_gcp1_aws1.name
}

resource "google_compute_router_peer" "peer_gcp1_aws1" {
  name                      = "peer-gcp1-aws1"
  router                    = google_compute_router.gcp_router.name
  region                    = var.region
  peer_ip_address           = "169.254.13.1"
  peer_asn                  = 64512
  advertised_route_priority = 100
  interface                 = google_compute_router_interface.if_gcp1_aws1.name
}

# ============================================================
# Firewall — autoriser BGP (TCP 179) depuis les tunnels
# ============================================================

resource "google_compute_firewall" "allow_bgp" {
  name    = "allow-bgp-vpn"
  network = google_compute_network.secure_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["179"]
  }

  source_ranges = [
    "169.254.10.0/30",
    "169.254.11.0/30",
    "169.254.12.0/30",
    "169.254.13.0/30"
  ]
  description = "Allow BGP from VPN tunnel link-local ranges"
}

# ============================================================
# Outputs
# ============================================================

output "gcp_vpn_interface_0_ip" {
  value       = google_compute_ha_vpn_gateway.gcp_ha_vpn.vpn_interfaces[0].ip_address
  description = "GCP VPN Interface 0 IP"
}

output "gcp_vpn_interface_1_ip" {
  value       = google_compute_ha_vpn_gateway.gcp_ha_vpn.vpn_interfaces[1].ip_address
  description = "GCP VPN Interface 1 IP"
}
