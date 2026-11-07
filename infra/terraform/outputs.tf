output "public_ip" {
  description = "Public IPv4 address for DNS records and SSH."
  value       = oci_core_instance.apigw.public_ip
}

output "ssh_command" {
  description = "Command to connect to the VM."
  value       = "ssh ubuntu@${oci_core_instance.apigw.public_ip}"
}
