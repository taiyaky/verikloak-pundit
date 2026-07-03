# frozen_string_literal: true

module Verikloak
  module Pundit
    # Maps roles to permissions using project configuration.
    module RoleMapper
      module_function

      # Map a Keycloak role to a domain permission via configuration.
      #
      # @param role [String, Symbol] Role name from JWT claims
      # @param config [Configuration] Configuration providing the role_map
      # @return [String, Symbol] Mapped permission (or the role itself if unmapped)
      def map(role, config)
        config.role_map[role.to_sym] || role
      end

      # Resolve the permission granted by a role, honoring strict mode.
      #
      # @param role [String, Symbol] Role name from JWT claims
      # @param config [Configuration] Configuration providing role_map and strict_permissions
      # @return [String, Symbol, nil] Mapped permission, the role itself when
      #   unmapped and strict mode is off, or nil when unmapped in strict mode
      def permission_for(role, config)
        mapped = config.role_map[role.to_sym]
        return mapped if mapped

        config.strict_permissions ? nil : role
      end
    end
  end
end
