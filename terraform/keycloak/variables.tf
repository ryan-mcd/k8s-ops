variable "keycloak_realm" {
  type      = string
  default   = ""
}

variable "bind_credential" {
  sensitive   = true
  description = "LDAP Bind Credential for glauth SA"
  type        = string
  default     = ""
}

variable "keycloak_addr" {
  description = "keycloak url not including protocol"
  type        = string
  default     = ""
}

variable "keycloak_user" {
  sensitive   = true
  description = "keycloak admin user"
  type        = string
  default     = ""
}

variable "keycloak_password" {
  sensitive   = true
  description = "keycloak admin password"
  type        = string
  default     = ""
}

variable "harbor_addr" {
  sensitive   = false
  description = "harbor url not including protocol"
  type        = string
  default     = ""
}

variable "harbor_id" {
  sensitive   = true
  description = "harbor client id and name"
  type        = string
  default     = ""
}

variable "neuvector_addr" {
  sensitive   = false
  description = "neuvector url not including protocol"
  type        = string
  default     = ""
}

variable "neuvector_id" {
  sensitive   = true
  description = "neuvector client id and name"
  type        = string
  default     = ""
}

variable "gitea_addr" {
  sensitive   = false
  description = "neuvector url not including protocol"
  type        = string
  default     = ""
}

variable "gitea_id" {
  sensitive   = true
  description = "neuvector client id and name"
  type        = string
  default     = ""
}