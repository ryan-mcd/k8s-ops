terraform {
  cloud {
    organization = "mcd-infra"

    workspaces {
      name = "hetzner-proxy"
    }
  }
  required_providers {
    sops = {
      source  = "carlpett/sops"
      version = "0.7.2"
    }
    hcloud = {
      source = "hetznercloud/hcloud"
      version = "1.42.0"
    }
  }
}
provider "sops" {
}

# data "sops_file" "secrets" {
#  source_file = ".secrets.sops.yaml"
# }

# Configure the Hetzner Cloud Provider
provider "hcloud" {
    token = var.hcloud_token
#   token = data.sops_file.secrets.data["hcloud_token"]
}