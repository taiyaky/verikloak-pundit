# frozen_string_literal: true

# Verikloak::Pundit initializer
# Configure how to read roles from Keycloak claims and how to map them
# into application permissions.
Verikloak::Pundit.configure do |c|
  c.resource_client = ENV.fetch('KEYCLOAK_RESOURCE_CLIENT', 'rails-api')
  c.role_map = {
    # admin:  :manage_all,
    # editor: :write_notes,
    # reader: :read_notes
  }
  c.env_claims_key = 'verikloak.user'
  # claims['realm_access']['roles']
  c.realm_roles_path    = %w[realm_access roles]
  # rubocop:disable Style/SymbolProc -- we need a Proc object here, not block pass
  # claims['resource_access'][resource_client]['roles']
  c.resource_roles_path = ['resource_access', ->(cfg) { cfg.resource_client }, 'roles']
  # rubocop:enable Style/SymbolProc
  # Permission mapping scope:
  #   :default_resource => realm roles + default client roles (recommended)
  #   :all_resources    => realm roles + roles from all clients in resource_access
  c.permission_role_scope = :default_resource
end
