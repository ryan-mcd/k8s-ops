#------------------------------------------------------------------------------#
# OIDC client
#------------------------------------------------------------------------------#

resource "vault_identity_oidc_key" "keycloak_provider_key" {
  name      = "keycloak"
  algorithm = "RS256"
}

resource "vault_jwt_auth_backend" "keycloak" {
  path               = "oidc"
  type               = "oidc"
  default_role       = "default"
  oidc_discovery_url = format("https://${data.sops_file.secrets.data["keycloak_addr"]}/auth/realms/%s" ,data.keycloak_realm.realm.id)
  oidc_client_id     = keycloak_openid_client.openid_client.client_id
  oidc_client_secret = keycloak_openid_client.openid_client.client_secret

  tune {
    audit_non_hmac_request_keys  = []
    audit_non_hmac_response_keys = []
    default_lease_ttl            = "1h"
    listing_visibility           = "unauth"
    max_lease_ttl                = "1h"
    passthrough_request_headers  = []
    token_type                   = "default-service"
  }
}

resource "vault_jwt_auth_backend_role" "default" {
  backend        = vault_jwt_auth_backend.keycloak.path
  role_name      = "default"
  token_ttl      = 3600
  token_max_ttl  = 3600

  bound_audiences = [keycloak_openid_client.openid_client.client_id]
  user_claim      = "sub"
  claim_mappings = {
    preferred_username = "username"
    email              = "email"
  }
  role_type             = "oidc"
  allowed_redirect_uris = ["https://${data.sops_file.secrets.data["vault_addr"]}/ui/vault/auth/oidc/oidc/callback", "http://localhost:8250/oidc/callback"]
  groups_claim          = format("/resource_access/%s/roles",keycloak_openid_client.openid_client.client_id)
}

#------------------------------------------------------------------------------#
# Vault engines
#------------------------------------------------------------------------------#

resource "vault_mount" "secret" {
  path        = "secret"
  type        = "kv-v2"
  description = "KV2 Secrets Engine"
}

resource "vault_mount" "sops" {
  path        = "sops"
  type        = "transit"
  description = "This is the transit engine for SOPS"
  default_lease_ttl_seconds = 3600
  max_lease_ttl_seconds     = 86400

  options = {
    convergent_encryption = false
  }
}

resource "vault_transit_secret_backend_key" "sops_user_key" {
  backend = vault_mount.sops.path
  name    = "sops-user"
}

#------------------------------------------------------------------------------#
# Vault policies
#------------------------------------------------------------------------------#
module "reader" {
  source = "./external_group"
  external_accessor = vault_jwt_auth_backend.keycloak.accessor
  vault_identity_oidc_key_name = vault_identity_oidc_key.keycloak_provider_key.name
  groups = [
    {
      group_name = "reader"
      rules = [
        {
          path         = "/secret/*"
          capabilities = ["read", "list"]
        }
      ]
    }
  ]
}

module "management" {
  source = "./external_group"
  external_accessor = vault_jwt_auth_backend.keycloak.accessor
  vault_identity_oidc_key_name = vault_identity_oidc_key.keycloak_provider_key.name
  groups = [
    {
      group_name = "management"
      rules = [
        {
          path         = "/secret/*"
          capabilities = ["create", "read", "update", "delete", "list"]
        }
      ]
    }
  ]
}

module "admin" {
  source = "./external_group"
  external_accessor = vault_jwt_auth_backend.keycloak.accessor
  vault_identity_oidc_key_name = vault_identity_oidc_key.keycloak_provider_key.name
  groups = [
    {
      group_name = "admin"
      rules = [
        # ## GOD MODE
        # {
        # path         = "*"
        # capabilities = [ "sudo", "read", "create", "update", "delete", "list", "patch" ]
        # },

        ## AUTH POLICIES OIDC
        # Mount the OIDC auth method
        {
        path         = "sys/auth/oidc"
        capabilities = [ "create", "read", "update", "delete", "sudo" ]
        },

        # Configure the OIDC auth method
        {
        path         = "auth/oidc/*"
        capabilities = [ "create", "read", "update", "delete", "list" ]
        },

        ## ADMIN POLICIES FOR SOPS

        # Manage the transit secrets engine
        {
        path         = "sops/*"
        capabilities = [ "create", "read", "update", "delete", "list" ]
        },

        ## ADMIN POLICIES FOR PKI

        # Manage the pki secrets engine
        {
        path         = "pki*"
        capabilities = [ "create", "read", "update", "delete", "list", "sudo" ]
        },

        ## ADMIN POLICIES FROM DOCS @ https://www.hashicorp.com/resources/policies-vault
        # Manage auth backends broadly across Vault
        {
        path         = "auth/*"
        capabilities = ["create", "read", "update", "delete", "list", "sudo"]
        },

        # List, create, update, and delete auth backends
        {
        path         = "sys/auth/*"
        capabilities = ["create", "read", "update", "delete", "sudo"]
        },

        # To list policies - Step 3
        {
        path         = "sys/policy"
        capabilities = ["read"]
        },

        # Create and manage ACL policies broadly across Vault
        {
        path         = "sys/policy/*"
        capabilities = ["create", "read", "update", "delete", "list", "sudo"]
        },

        # List, create, update, and delete key/value secrets
        {
        path         = "secret/*"
        capabilities = ["create", "read", "update", "delete", "list", "sudo"]
        },

        # Manage and manage secret backends broadly across Vault.
        {
        path         = "sys/mounts/*"
        capabilities = ["create", "read", "update", "delete", "list", "sudo"]
        },

        # Read health checks
        {
        path         = "sys/health"
        capabilities = ["read", "sudo"]
        },

        # To perform Step 4
        {
        path         = "sys/capabilities"
        capabilities = ["create", "update"]
        },

        # To perform Step 4
        {
        path         = "sys/capabilities-self"
        capabilities = ["create", "update"]
        },

        ## ADMIN POLICIES FROM https://github.com/tvories/k8s-gitops/blob/dcbf1363d7d88ae19d1e306bdd1c352ed60355f9/k8s/clusters/cluster-0/manifests/selfhosted/hashi-vault/config/policies/admin.hcl

        # Manage auth methods broadly across Vault
        {
        path         = "auth/*"
        capabilities = ["create", "read", "update", "delete", "list", "sudo"]
        },

        # Create, update, and delete auth methods
        {
        path         = "sys/auth/*"
        capabilities = ["create", "update", "delete", "sudo"]
        },

        # List auth methods
        {
        path         = "sys/auth"
        capabilities = ["read"]
        },

        # List existing policies
        {
        path         = "sys/policies/acl"
        capabilities = ["list"]
        },

        # Create and manage all policies
        {
        path         = "sys/policies/*"
        capabilities = ["create", "read", "update", "delete", "list", "sudo"]
        },
        # Create and manage ACL policies
        {
        path         = "sys/policies/acl/*"
        capabilities = ["create", "read", "update", "delete", "list", "sudo"]
        },

        # List, create, update, and delete key/value secrets
        {
        path         = "secret/*"
        capabilities = ["create", "read", "update", "delete", "list", "sudo"]
        },

        # Manage secrets engines
        {
        path         = "sys/mounts/*"
        capabilities = ["create", "read", "update", "delete", "list", "sudo"]
        },

        # List existing secrets engines.
        {
        path         = "sys/mounts"
        capabilities = ["read"]
        },

        # Read health checks
        {
        path         = "sys/health"
        capabilities = ["read", "sudo"]
        },

        # Mount the AppRole auth method
        {
        path         = "sys/auth/approle"
        capabilities = [ "create", "read", "update", "delete", "sudo" ]
        },

        # Configure the AppRole auth method
        {
        path         = "sys/auth/approle/*"
        capabilities = [ "create", "read", "update", "delete" ]
        },

        # Create and manage roles
        {
        path         = "auth/approle/*"
        capabilities = [ "create", "read", "update", "delete", "list" ]
        },

        # Manage tokens for verification
        {
        path         = "auth/token/create"
        capabilities = [ "create", "read", "update", "delete", "list" ]
        },

        # Manage the leases
        {
        path         = "sys/leases/*"
        capabilities = [ "create", "read", "update", "delete", "list" ]
        },

        # Link existing policies
        {
        path         = "sys/policy"
        capabilities = ["read"]
        },

        # Create and manage ACL policies broadly across Vault
        {
        path         = "sys/policy/*"
        capabilities = ["create", "read", "update", "delete", "list", "sudo"]
        },

        # Backup raft snapshots
        {
        path         = "sys/storage/raft/snapshot"
        capabilities = ["read"]
        },

        {
        path         = "identity/*"
        capabilities = ["create", "read", "update", "delete", "list", "sudo"]
        }
      ]
    }
  ]
}
