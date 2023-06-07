data "sops_file" "secrets" {
 source_file = ".secrets.sops.yaml"
}

data "keycloak_realm" "realm" {
    realm = data.sops_file.secrets.data["keycloak_realm"]
}