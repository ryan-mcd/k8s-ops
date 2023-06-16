# Defined in terraform cloud
variable "cloudflare_apikey" {
  sensitive = true
  type      = string
  default   = ""
}

# Defined in terraform cloud
variable "cloudflare_email" {
  sensitive   = true
  type        = string
  default     = ""
}

variable "cloudflare_account_id" {
  sensitive   = true
  type        = string
  default     = ""
}