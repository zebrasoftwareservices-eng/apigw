variable "tenancy_ocid" {
  description = "Oracle Cloud tenancy OCID."
  type        = string
}

variable "compartment_ocid" {
  description = "Compartment in which to create the gateway resources."
  type        = string
}

variable "region" {
  description = "Oracle Cloud home region, for example us-ashburn-1."
  type        = string
}

variable "oci_profile" {
  description = "Profile name in ~/.oci/config."
  type        = string
  default     = "DEFAULT"
}

variable "ssh_public_key_path" {
  description = "Local path to the SSH public key installed for the ubuntu user."
  type        = string
  default     = "~/.ssh/id_ed25519.pub"
}

variable "ssh_allowed_cidr" {
  description = "IPv4 CIDR allowed to SSH. Restrict this to your public IP when practical."
  type        = string
  default     = "0.0.0.0/0"
}

variable "instance_ocpus" {
  description = "Ampere A1 OCPUs. Keep within the Always Free allowance."
  type        = number
  default     = 2
}

variable "instance_memory_gb" {
  description = "Ampere A1 memory in GB. Keep within the Always Free allowance."
  type        = number
  default     = 12
}

variable "boot_volume_size_gb" {
  description = "Boot volume size in GB. Oracle images require at least about 47 GB."
  type        = number
  default     = 50
}
