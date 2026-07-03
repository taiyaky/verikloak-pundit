# frozen_string_literal: true

# Verikloak::Pundit initializer
#
# Most settings are auto-configured from environment variables and verikloak-rails.
# Uncomment and customize only what you need to override.
#
# Environment variables supported:
#   KEYCLOAK_RESOURCE_CLIENT - resource client ID (default: 'rails-api')
#
# When used with verikloak-rails, env_claims_key is automatically synchronized.
Verikloak::Pundit.configure do |c|
  # Resource client (optional - falls back to ENV['KEYCLOAK_RESOURCE_CLIENT'] or 'rails-api')
  # c.resource_client = ENV.fetch('KEYCLOAK_RESOURCE_CLIENT', 'rails-api')

  # Role to permission mapping (optional)
  # c.role_map = {
  #   admin:  :manage_all,
  #   editor: :write_notes,
  #   reader: :read_notes
  # }

  # Only grant permissions defined as role_map values (optional, default: false).
  # When true, bare role names no longer act as implicit permissions in
  # has_permission?. Recommended with permission_role_scope = :all_resources.
  # c.strict_permissions = true

  # Uncomment to customize JWT claims path and scope (usually not needed):
  # c.env_claims_key = 'verikloak.user'
  # c.realm_roles_path = %w[realm_access roles]
  # c.resource_roles_path = ['resource_access', ->(cfg, client) { client || cfg.resource_client }, 'roles']
  # c.permission_role_scope = :default_resource  # or :all_resources
end
