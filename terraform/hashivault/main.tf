terraform {

  required_providers {
    sops = {
      source  = "carlpett/sops"
      version = "0.7.2"
    }
    vault = {
      source = "hashicorp/vault"
      version = ">= 3.15.0"
    }
    keycloak = {
      source = "mrparkers/keycloak"
      version = ">= 4.2.0"
    }
  }
}
provider "sops" {
}

provider "vault" {
  address = "https://${data.sops_file.secrets.data["vault_addr"]}"
  token   = data.sops_file.secrets.data["vault_root_token"]
}

provider "keycloak" {
  client_id = "admin-cli"
  username  = data.sops_file.secrets.data["keycloak_user"]
  password  = data.sops_file.secrets.data["keycloak_password"]
  # client_id     = "terraform"
  # client_secret = ""
  base_path = "/auth"
  url       = "https://${data.sops_file.secrets.data["keycloak_addr"]}"
}