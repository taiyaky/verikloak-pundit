# frozen_string_literal: true

module Verikloak
  module Pundit
    # Maps roles to permissions using project configuration.
    module RoleMapper
      module_function

      # Map a Keycloak role to a domain permission via configuration.
      #
      # @deprecated Use {.permission_for} instead. This method now delegates
      #   to it so that strict mode and explicit nil revocations are honored
      #   consistently by every caller.
      # @param role [String, Symbol] Role name from JWT claims
      # @param config [Configuration] Configuration providing the role_map
      # @return [String, Symbol, nil] see {.permission_for}
      def map(role, config)
        permission_for(role, config)
      end

      # Resolve the permission granted by a role, honoring strict mode.
      # A role explicitly mapped to nil grants nothing even when strict mode
      # is off — an explicit revocation of the role's implicit permission.
      #
      # @param role [String, Symbol] Role name from JWT claims
      # @param config [Configuration] Configuration providing role_map and strict_permissions
      # @return [String, Symbol, nil] Mapped permission, the role itself when
      #   unmapped and strict mode is off, or nil when unmapped in strict mode
      #   or explicitly mapped to nil
      def permission_for(role, config)
        key = role.to_sym
        return config.role_map[key] if config.role_map.key?(key)

        config.strict_permissions ? nil : role
      end
    end
  end
end
