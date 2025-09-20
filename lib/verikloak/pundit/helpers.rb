# frozen_string_literal: true

module Verikloak
  module Pundit
    # Helpers expose convenient delegations to the policy `user`.
    module Helpers
      # Check whether the user has a realm role.
      # @param role [String, Symbol]
      # @return [Boolean]
      def has_role?(role) = user.has_role?(role) # rubocop:disable Naming/PredicatePrefix

      # Check whether the user belongs to a group (alias to role).
      # @param group [String, Symbol]
      # @return [Boolean]
      def in_group?(group) = user.in_group?(group)

      # Check whether the user has a role for a specific resource client.
      # @param client [String, Symbol]
      # @param role [String, Symbol]
      # @return [Boolean]
      def resource_role?(client, role) = user.resource_role?(client, role)

      # Check whether the user has a mapped permission.
      # @param perm [String, Symbol]
      # @return [Boolean]
      def has_permission?(perm) = user.has_permission?(perm) # rubocop:disable Naming/PredicatePrefix
    end
  end
end
