terraform {

}
terraform {
  cloud {
    organization = "mcd-infra"

    workspaces {
      name = "keycloak-oci"
    }
  }
  required_providers {
    sops = {
      source  = "carlpett/sops"
      version = "0.7.2"
    }
    keycloak = {
      source = "mrparkers/keycloak"
      version = ">= 4.2.0"
    }
  }
}
provider "sops" {
}

# provider "keycloak" {
#   client_id = "admin-cli"
#   username  = var.keycloak_user
#   password  = var.keycloak_password
#   # client_id     = "terraform"
#   # client_secret = ""
#   base_path = "/auth"
#   url       = "https://${var.keycloak_addr}"
# }

# Required until terraform cloud-agent can be deployed
provider "keycloak" {
  # # Required until after keycloak_openid_client.terraform_client_api exists
  # client_id = "admin-cli"
  # username  = data.sops_file.secrets.data["keycloak_user"]
  # password  = data.sops_file.secrets.data["keycloak_password"]

  client_id           = data.sops_file.secrets.data["terraform_client"]
  client_secret       = data.sops_file.secrets.data["terraform_client_secret"]

  base_path = "/auth"
  url       = "https://${data.sops_file.secrets.data["keycloak_addr"]}"
}
data "sops_file" "secrets" {
 source_file = ".secrets.sops.yaml"
}

