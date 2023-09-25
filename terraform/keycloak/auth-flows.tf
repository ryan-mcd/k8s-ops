# https://keycloak.ch/keycloak-tutorials/tutorial-webauthn/

resource "keycloak_required_action" "webauthn_register_action" {
  realm_id = keycloak_realm.realm.realm
  alias    = "webauthn-register"
  enabled  = true
  name     = "Webauthn Register"
}

resource "keycloak_required_action" "webauthn_register_passwordless_action" {
  realm_id       = keycloak_realm.realm.realm
  alias          = "webauthn-register-passwordless"
  enabled        = true
  default_action = true
  name           = "Webauthn Passwordless Register"
}

resource "keycloak_authentication_flow" "browser_webauthn_otp" {
  realm_id    = keycloak_realm.realm.id
  alias       = "Browser-WebAuthnOTP"
  provider_id = "basic-flow"
}

resource "keycloak_authentication_execution" "auth_cookie" {
  realm_id          = keycloak_realm.realm.id
  parent_flow_alias = keycloak_authentication_flow.browser_webauthn_otp.alias
  authenticator     = "auth-cookie"
  requirement       = "ALTERNATIVE"
}

resource "keycloak_authentication_subflow" "root_subflow" {
  realm_id          = keycloak_realm.realm.id
  alias             = "root-subflow"
  parent_flow_alias = keycloak_authentication_flow.browser_webauthn_otp.alias
  provider_id       = "basic-flow"
  requirement       = "ALTERNATIVE"
}

resource "keycloak_authentication_subflow" "root_form_subflow" {
  realm_id          = keycloak_realm.realm.id
  alias             = "root-form"
  parent_flow_alias = keycloak_authentication_flow.browser_webauthn_otp.alias
  provider_id       = "form-flow"
  requirement       = "DISABLED"
}

# second execution
resource "keycloak_authentication_execution" "username_form" {
  realm_id          = keycloak_realm.realm.id
  parent_flow_alias = keycloak_authentication_subflow.root_subflow.alias
  requirement       = "REQUIRED"
  authenticator     = "auth-username-form"

  depends_on = [
    keycloak_authentication_execution.auth_cookie
  ]
}

resource "keycloak_authentication_subflow" "passwordless_or_2fa_subflow" {
  realm_id          = keycloak_realm.realm.id
  alias             = "passwordless-or-2fa"
  parent_flow_alias = keycloak_authentication_subflow.root_subflow.alias
  provider_id       = "basic-flow"
  requirement       = "REQUIRED"
}

resource "keycloak_authentication_execution" "auth_webauthn_passwordless" {
  realm_id          = keycloak_realm.realm.id
  parent_flow_alias = keycloak_authentication_subflow.passwordless_or_2fa_subflow.alias
  authenticator     = "webauthn-authenticator-passwordless"
  requirement       = "ALTERNATIVE"

  depends_on = [
    keycloak_authentication_execution.username_form
  ]
}

resource "keycloak_authentication_subflow" "password_2fa_subflow" {
  realm_id          = keycloak_realm.realm.id
  alias             = "Password and 2FA"
  parent_flow_alias = keycloak_authentication_subflow.passwordless_or_2fa_subflow.alias
  provider_id       = "basic-flow"
  requirement       = "ALTERNATIVE"
}

resource "keycloak_authentication_execution" "auth_password" {
  realm_id          = keycloak_realm.realm.id
  parent_flow_alias = keycloak_authentication_subflow.password_2fa_subflow.alias
  authenticator     = "auth-password-form"
  requirement       = "REQUIRED"

  depends_on = [
    keycloak_authentication_execution.auth_webauthn_passwordless
  ]
}

resource "keycloak_authentication_subflow" "auth_2fa_subflow" {
  realm_id          = keycloak_realm.realm.id
  alias             = "2FA"
  parent_flow_alias = keycloak_authentication_subflow.password_2fa_subflow.alias
  provider_id       = "basic-flow"
  requirement       = "CONDITIONAL"
}

resource "keycloak_authentication_execution" "user_configured" {
  realm_id          = keycloak_realm.realm.id
  parent_flow_alias = keycloak_authentication_subflow.auth_2fa_subflow.alias
  authenticator     = "conditional-user-configured"
  requirement       = "REQUIRED"

  depends_on = [
    keycloak_authentication_execution.auth_password
  ]
}

resource "keycloak_authentication_execution" "auth_webauthn" {
  realm_id          = keycloak_realm.realm.id
  parent_flow_alias = keycloak_authentication_subflow.auth_2fa_subflow.alias
  authenticator     = "webauthn-authenticator"
  requirement       = "ALTERNATIVE"

  depends_on = [
    keycloak_authentication_execution.auth_password
  ]
}

resource "keycloak_authentication_execution" "auth_otp" {
  realm_id          = keycloak_realm.realm.id
  parent_flow_alias = keycloak_authentication_subflow.auth_2fa_subflow.alias
  authenticator     = "auth-otp-form"
  requirement       = "ALTERNATIVE"

  depends_on = [
    keycloak_authentication_execution.auth_password
  ]
}
