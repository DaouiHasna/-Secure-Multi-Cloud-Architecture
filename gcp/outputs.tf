output "service_account_email" {
  value = google_service_account.security_sa.email
}
output "vm_name" {
  value = google_compute_instance.secure_vm_sa.name
}
output "vm_internal_ip" {
  value = google_compute_instance.secure_vm_sa.network_interface[0].network_ip
}
output "bucket_name" {
  value = google_storage_bucket.audit_logs_bucket.name
}
output "gcp_vpn_ip0" {
  value = google_compute_ha_vpn_gateway.gcp_ha_vpn.vpn_interfaces[0].ip_address
}
output "gcp_vpn_ip1" {
  value = google_compute_ha_vpn_gateway.gcp_ha_vpn.vpn_interfaces[1].ip_address
}
