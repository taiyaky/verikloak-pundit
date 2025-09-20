# frozen_string_literal: true

module Verikloak
  module Pundit
    # Runtime configuration for verikloak-pundit.
    #
    # @!attribute resource_client
    #   @return [String] default Keycloak resource client used for resource roles
    # @!attribute role_map
    #   @return [Hash{Symbol=>Symbol,String}] mapping from roles to permissions
    # @!attribute env_claims_key
    #   @return [String] Rack env key where claims are stored (when using verikloak/verikloak-rails)
    # @!attribute realm_roles_path
    #   @return [Array<String,Proc>] path inside JWT claims to reach realm roles
    # @!attribute resource_roles_path
    #   @return [Array<String,Proc>] path inside JWT claims to reach resource roles
    # @!attribute permission_role_scope
    #   @return [Symbol] :default_resource or :all_resources for permission mapping scope
    class Configuration
      attr_accessor :resource_client, :role_map, :env_claims_key,
                    :realm_roles_path, :resource_roles_path,
                    :permission_role_scope

      # Initialize default configuration values.
      def initialize
        @resource_client   = 'rails-api'
        @role_map          = {} # e.g., { admin: :manage_all }
        @env_claims_key    = 'verikloak.user'
        @realm_roles_path  = %w[realm_access roles]
        # rubocop:disable Style/SymbolProc -- we need a Proc object here, not block pass
        @resource_roles_path = ['resource_access', ->(cfg) { cfg.resource_client }, 'roles']
        # rubocop:enable Style/SymbolProc
        # :default_resource (realm + default client), :all_resources (realm + all clients)
        @permission_role_scope = :default_resource
      end
    end
  end
end
