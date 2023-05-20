resource "keycloak_openid_client" "openid_client" {
  realm_id            = data.keycloak_realm.realm.id
  client_id           = "hashivault"

  name                = "hashivault"
  enabled             = true
  standard_flow_enabled = true

  access_type         = "CONFIDENTIAL"
  valid_redirect_uris = [
    "https://${data.sops_file.secrets.data["vault_addr"]}/*"
  ]
  # root_url =
  # web_origins =
  # admin_url =

}


resource "keycloak_openid_user_client_role_protocol_mapper" "user_client_role_mapper" {
  realm_id   = data.keycloak_realm.realm.id
  client_id  = keycloak_openid_client.openid_client.id
  name       = "user-client-role-mapper"
  claim_name = format("resource_access.%s.roles",keycloak_openid_client.openid_client.client_id)
  multivalued = true
}

resource "keycloak_role" "management_role" {
  realm_id    = data.keycloak_realm.realm.id
  client_id   = keycloak_openid_client.openid_client.id
  name        = "management"
  description = "Management role"
  composite_roles = [
    keycloak_role.reader_role.id
  ]
}

resource "keycloak_role" "reader_role" {
  realm_id    = data.keycloak_realm.realm.id
  client_id   = keycloak_openid_client.openid_client.id
  name        = "reader"
  description = "Reader role"
}