resource "google_compute_network" "secure_vpc" {
  name                    = var.vpc_name
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "secure_subnet" {
  name          = var.subnet_name
  ip_cidr_range = var.subnet_cidr
  region        = var.region
  network       = google_compute_network.secure_vpc.id
}

resource "google_compute_firewall" "allow_internal" {
  name    = var.firewall_name
  network = google_compute_network.secure_vpc.name

  allow {
    protocol = "tcp"
  }
  allow {
    protocol = "udp"
  }
  allow {
    protocol = "icmp"
  }

  # subnet GCP + VPC AWS autorisés
  source_ranges = [var.subnet_cidr, "10.0.0.0/16"]
}
