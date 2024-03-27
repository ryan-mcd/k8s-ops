terraform {

}
terraform {
  cloud {
    organization = "mcd-infra"

    workspaces {
      name = "cloudflare"
    }
  }
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "4.21.0"
    }
    sops = {
      source  = "carlpett/sops"
      version = "1.0.0"
    }
    keycloak = {
      source = "mrparkers/keycloak"
      version = ">= 4.2.0"
    }
  }
}
provider "sops" {
}

# data "sops_file" "secrets" {
#  source_file = ".secrets.sops.yaml"
# }

provider "cloudflare" {
  email   = var.cloudflare_email
  api_key = var.cloudflare_apikey
}

