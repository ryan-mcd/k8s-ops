# Defined in terraform cloud
variable "hcloud_token" {
  sensitive = true
  type      = string
  default   = ""
}

# Defined in terraform cloud
variable "backend_ip" {
  description = "IP for HAProxy to forward to"
  type        = string
  default     = ""
}

# Defined in terraform cloud
variable "sni_domain1" {
  description = "SNI domain1 to listen for"
  type        = string
  default     = ""
}

# Defined in terraform cloud
variable "allowed_ssh_ips" {
  description = "IPs to allow ssh connections from"
  type        = list(string)
  default     = [""]
}

variable "ssh_authorized_keys" {
  description = "list of public keys to add as authorized ssh keys"
  type        = list(string)
  default     = ["ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMhRYUuIEXcUuGEWnmkXeZFN890IWSRJrDCy4GHw4uxG"]
}

variable "extra_cloud_config_config" {
  description = "extra config to append to cloud-config"
  type        = string
  default     = ""
}
