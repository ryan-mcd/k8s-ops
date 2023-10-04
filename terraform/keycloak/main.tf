resource "keycloak_realm" "realm" {
    enabled                                     = true
    realm                                       = data.sops_file.secrets.data["keycloak_realm"]
    default_signature_algorithm                 = "RS256"
    # browser_flow                                = "browser-plus-otp"
    # access_code_lifespan                     = "1m0s"
    # access_code_lifespan_login               = "30m0s"
    # access_code_lifespan_user_action         = "5m0s"
    # access_token_lifespan                    = "5m0s"
    # access_token_lifespan_for_implicit_flow  = "15m0s"
    # action_token_generated_by_admin_lifespan = "12h0m0s"
    # action_token_generated_by_user_lifespan  = "5m0s"
    # attributes                               = {}
    # client_authentication_flow               = "clients"
    # client_session_idle_timeout              = "0s"
    # client_session_max_lifespan              = "0s"
    # default_default_client_scopes            = []
    # default_optional_client_scopes           = []
    # direct_grant_flow                        = "direct grant"
    # docker_authentication_flow               = "docker auth"
    # duplicate_emails_allowed                 = false
    # edit_username_allowed                    = false
    # login_with_email_allowed                 = true
    # oauth2_device_code_lifespan              = "10m0s"
    # oauth2_device_polling_interval           = 5
    # offline_session_idle_timeout             = "720h0m0s"
    # offline_session_max_lifespan             = "1440h0m0s"
    # offline_session_max_lifespan_enabled     = false
    # refresh_token_max_reuse                  = 0
    # registration_allowed                     = false
    # registration_email_as_username           = false
    # registration_flow                        = "registration"
    # remember_me                              = false
    # reset_credentials_flow                   = "reset credentials"
    # reset_password_allowed                   = false
    # revoke_refresh_token                     = false
    # ssl_required                             = "external"
    # sso_session_idle_timeout                 = "30m0s"
    # sso_session_idle_timeout_remember_me     = "0s"
    # sso_session_max_lifespan                 = "10h0m0s"
    # sso_session_max_lifespan_remember_me     = "0s"
    # user_managed_access                      = false
    # verify_email                             = false

    # otp_policy {
    #     algorithm         = "HmacSHA256"
    #     digits            = 6
    #     initial_counter   = 0
    #     look_ahead_window = 1
    #     period            = 30
    #     type              = "totp"
    # }

    web_authn_passwordless_policy {
        user_verification_requirement     = "required"
        # acceptable_aaguids                = []
        # attestation_conveyance_preference = "not specified"
        # authenticator_attachment          = "not specified"
        # avoid_same_authenticator_register = false
        # create_timeout                    = 0
        # relying_party_entity_name         = "keycloak"
        # require_resident_key              = "not specified"
        # signature_algorithms              = [
        #     "ES256",
        # ]
    }

    # web_authn_policy {
    #     acceptable_aaguids                = []
    #     attestation_conveyance_preference = "not specified"
    #     authenticator_attachment          = "not specified"
    #     avoid_same_authenticator_register = false
    #     create_timeout                    = 0
    #     relying_party_entity_name         = "keycloak"
    #     require_resident_key              = "not specified"
    #     signature_algorithms              = [
    #         "ES256",
    #     ]
    #     user_verification_requirement     = "not specified"
    # }
}

resource "keycloak_openid_client" "terraform_client_api" {
  realm_id            = "master"
  name                = data.sops_file.secrets.data["terraform_client"]
  client_id           = data.sops_file.secrets.data["terraform_client"]
  client_secret       = data.sops_file.secrets.data["terraform_client_secret"]

  enabled                      = true
  standard_flow_enabled        = false
  direct_access_grants_enabled = false
  service_accounts_enabled     = true

  access_type         = "CONFIDENTIAL"
}

resource "keycloak_openid_client_service_account_realm_role" "terraform_client_service_account_role" {
  realm_id                = "master"
  service_account_user_id = keycloak_openid_client.terraform_client_api.service_account_user_id
  role                    = data.sops_file.secrets.data["terraform_client_role"]
}


resource "keycloak_ldap_user_federation" "glauth" {
    enabled                         = true
    realm_id                        = keycloak_realm.realm.id
    name                            = "ldap"
    vendor                          = "OTHER"
    username_ldap_attribute         = "uid"
    rdn_ldap_attribute              = "uid"
    uuid_ldap_attribute             = "uid"
    user_object_classes             = [
        "posixAccount",
    ]
    connection_url                  = "ldap://glauth.sso.svc.cluster.local:389"
    users_dn                        = "ou=people,dc=home,dc=arpa"
    bind_dn                         = "cn=search,ou=svcaccts,dc=home,dc=arpa"
    bind_credential                 = var.bind_credential
    delete_default_mappers          = false
    import_enabled                  = true
    edit_mode                       = "READ_ONLY"
    full_sync_period                = 604800
    priority                        = 0
    search_scope                    = "SUBTREE"
    start_tls                       = false
    sync_registrations              = true
    trust_email                     = true
    use_truststore_spi              = "ONLY_FOR_LDAPS"
    validate_password_policy        = false
    # batch_size_for_sync             = 1000
    # changed_sync_period             = -1
    pagination                      = false # UI Defaults to false, tf-provider defaults to true
    # use_password_modify_extended_op = false
}

resource "keycloak_ldap_group_mapper" "glauth_ldap_group_mapper" {
    realm_id                             = keycloak_realm.realm.id
    ldap_user_federation_id              = keycloak_ldap_user_federation.glauth.id
    name                                 = "groups"
    drop_non_existing_groups_during_sync = false
    group_name_ldap_attribute            = "cn"
    group_object_classes                 = [
        "posixGroup",
    ]
    groups_path                          = "/"
    ignore_missing_groups                = false
    ldap_groups_dn                       = "dc=home,dc=arpa"
    mapped_group_attributes              = []
    memberof_ldap_attribute              = "memberOf"
    membership_attribute_type            = "UID"
    membership_ldap_attribute            = "memberUid"
    membership_user_ldap_attribute       = "uid"
    mode                                 = "READ_ONLY"
    preserve_group_inheritance           = false
    user_roles_retrieve_strategy         = "LOAD_GROUPS_BY_MEMBER_ATTRIBUTE"
}

resource "keycloak_openid_client" "harbor" {
  realm_id            = keycloak_realm.realm.id
  name                = data.sops_file.secrets.data["harbor_id"]
  client_id           = data.sops_file.secrets.data["harbor_id"]
  client_secret       = data.sops_file.secrets.data["harbor_client_secret"]

  enabled             = true
  standard_flow_enabled = true

  access_type         = "CONFIDENTIAL"
  valid_redirect_uris = [
    "https://${data.sops_file.secrets.data["harbor_addr"]}/c/oidc/callback",
  ]
  admin_url           = "https://${data.sops_file.secrets.data["harbor_addr"]}"
  root_url            = "https://${data.sops_file.secrets.data["harbor_addr"]}"
}

resource "keycloak_openid_client" "neuvector" {
  realm_id            = keycloak_realm.realm.id
  name                = data.sops_file.secrets.data["neuvector_id"]
  client_id           = data.sops_file.secrets.data["neuvector_id"]
  client_secret       = data.sops_file.secrets.data["neuvector_client_secret"]

  enabled             = true
  standard_flow_enabled = true

  access_type         = "CONFIDENTIAL"
  valid_redirect_uris = [
    "https://${data.sops_file.secrets.data["neuvector_addr"]}/openId_auth",
  ]
  admin_url           = "https://${data.sops_file.secrets.data["neuvector_addr"]}"
  root_url            = "https://${data.sops_file.secrets.data["neuvector_addr"]}"
}

resource "keycloak_openid_client" "gitea" {
  realm_id            = keycloak_realm.realm.id
  name                = data.sops_file.secrets.data["gitea_id"]
  client_id           = data.sops_file.secrets.data["gitea_id"]
  client_secret       = data.sops_file.secrets.data["gitea_client_secret"]

  enabled             = true
  standard_flow_enabled = true

  access_type         = "CONFIDENTIAL"
  valid_redirect_uris = [
    "https://${data.sops_file.secrets.data["gitea_addr"]}/user/oauth2/keycloak/callback",
  ]
  admin_url           = "https://${data.sops_file.secrets.data["gitea_addr"]}"
  root_url            = "https://${data.sops_file.secrets.data["gitea_addr"]}"
}

resource "keycloak_openid_client_scope" "gitea" {
  realm_id               = keycloak_realm.realm.id
  name                   = "gitea"
  description            = "gitea scope"
  include_in_token_scope = true
}

resource "keycloak_openid_group_membership_protocol_mapper" "gitea_group_membership_mapper" {
  realm_id  = keycloak_realm.realm.id
  client_scope_id = keycloak_openid_client_scope.gitea.id
  name      = "groups"

  claim_name = "groups"
}

resource "keycloak_openid_client_default_scopes" "gitea_client_default_scopes" {
  realm_id  = keycloak_realm.realm.id
  client_id = keycloak_openid_client.gitea.id

  default_scopes = [
    keycloak_openid_client_scope.gitea.name,
    "profile",
    "email",
    "roles",
    "web-origins",
    "acr"
  ]
}

resource "keycloak_openid_client" "rancher" {
  realm_id            = keycloak_realm.realm.id
  name                = data.sops_file.secrets.data["rancher_id"]
  client_id           = data.sops_file.secrets.data["rancher_id"]
  client_secret       = data.sops_file.secrets.data["rancher_client_secret"]

  enabled             = true
  standard_flow_enabled = true

  access_type         = "CONFIDENTIAL"
  valid_redirect_uris = [
    "https://${data.sops_file.secrets.data["rancher_addr"]}/verify-auth",
  ]
  admin_url           = "https://${data.sops_file.secrets.data["rancher_addr"]}"
  root_url            = "https://${data.sops_file.secrets.data["rancher_addr"]}"
}

resource "keycloak_openid_client_scope" "rancher" {
  realm_id               = keycloak_realm.realm.id
  name                   = "rancher"
  description            = "rancher scope"
  include_in_token_scope = true
}

resource "keycloak_openid_group_membership_protocol_mapper" "rancher_group_membership_mapper" {
  realm_id  = keycloak_realm.realm.id
  client_scope_id = keycloak_openid_client_scope.rancher.id
  name      = "Groups Mapper"

  claim_name          = "groups"
  add_to_id_token     = false
  add_to_access_token = false
}

resource "keycloak_openid_group_membership_protocol_mapper" "rancher_groups_path_mapper" {
  realm_id  = keycloak_realm.realm.id
  client_scope_id = keycloak_openid_client_scope.rancher.id
  name      = "Group Path"

  claim_name = "full_group_path"
  full_path  = true
}

resource "keycloak_openid_audience_protocol_mapper" "rancher_audience_mapper" {
  realm_id  = keycloak_realm.realm.id
  client_scope_id = keycloak_openid_client_scope.rancher.id
  name      = "Client Audience"

  included_custom_audience = data.sops_file.secrets.data["rancher_id"]
}

resource "keycloak_openid_client_default_scopes" "rancher_client_default_scopes" {
  realm_id  = keycloak_realm.realm.id
  client_id = keycloak_openid_client.rancher.id

  default_scopes = [
    keycloak_openid_client_scope.rancher.name,
    "profile",
    "email",
    "roles",
    "web-origins",
    "acr"
  ]
}