resource "google_compute_instance" "secure_vm_sa" {
  name         = "secure-vm-sa"
  machine_type = "e2-micro"
  zone         = var.zone

  tags = ["secure-vm"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.secure_subnet.id
  }

  service_account {
    email  = google_service_account.security_sa.email
    scopes = ["https://www.googleapis.com/auth/logging.write"]
  }

  metadata = {
    enable-oslogin = "TRUE"
  }

  shielded_instance_config {
    enable_secure_boot          = true
    enable_vtpm                 = true
    enable_integrity_monitoring = true
  }
}
