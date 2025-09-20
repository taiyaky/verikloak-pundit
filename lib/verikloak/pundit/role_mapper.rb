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
        return role unless config.role_map && !config.role_map.empty?

        config.role_map[role.to_sym] || role
      end
    end
  end
end
