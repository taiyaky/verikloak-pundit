# frozen_string_literal: true

module Verikloak
  module Pundit
    # Lightweight wrapper around Keycloak claims for Pundit policies.
    class UserContext
      attr_reader :claims, :resource_client

      # Create a new user context from JWT claims.
      #
      # @param claims [Hash] JWT claims issued by Keycloak
      # @param resource_client [String] default resource client name for resource roles
      def initialize(claims, resource_client: Verikloak::Pundit.config.resource_client)
        @claims = claims || {}
        @resource_client = resource_client.to_s
      end

      # Subject identifier from claims.
      # @return [String, nil]
      def sub
        claims['sub']
      end

      # Email or preferred username from claims.
      # @return [String, nil]
      def email
        claims['email'] || claims['preferred_username']
      end

      # Realm-level roles from claims based on configuration path.
      # @return [Array<String>]
      def realm_roles
        path = resolve_path(Verikloak::Pundit.config.realm_roles_path)
        Array(claims.dig(*path))
      end

      # Resource-level roles for a given client from claims based on configuration path.
      #
      # @param client [String] resource client id (defaults to configured resource_client)
      # @return [Array<String>]
      def resource_roles(client = resource_client)
        client = client.to_s
        path = resolve_path(Verikloak::Pundit.config.resource_roles_path, client: client)
        Array(claims.dig(*path))
      end

      # Check whether the user has a realm role.
      #
      # @param role [String, Symbol]
      # @return [Boolean]
      def has_role?(role) # rubocop:disable Naming/PredicatePrefix
        r = role.to_s
        realm_roles.include?(r)
      end

      # Alias to has_role? to align with group-based naming.
      #
      # @param group [String, Symbol]
      # @return [Boolean]
      def in_group?(group)
        has_role?(group)
      end

      # Check whether the user has a role for a specific resource client.
      #
      # @param client [String, Symbol]
      # @param role [String, Symbol]
      # @return [Boolean]
      def resource_role?(client, role)
        client = client.to_s
        r = role.to_s
        resource_roles(client).include?(r)
      end

      # Check whether the user has a mapped permission.
      #
      # Uses realm roles and resource roles depending on
      # {Configuration#permission_role_scope}.
      #
      # @param perm [String, Symbol] permission to check
      # @return [Boolean]
      def has_permission?(perm) # rubocop:disable Naming/PredicatePrefix
        pr = perm.to_sym
        roles = realm_roles + resource_roles_scope
        mapped = roles.map { |r| RoleMapper.map(r, Verikloak::Pundit.config) }
        mapped.map(&:to_sym).include?(pr)
      end

      # Build a user context from Rack env using configured claims key.
      #
      # @param env [Hash] Rack environment
      # @return [UserContext]
      def self.from_env(env)
        claims = env[Verikloak::Pundit.config.env_claims_key]
        new(claims)
      end

      private

      # Resolve a configured path into concrete dig segments.
      #
      # @param path_config [Array<String, Proc>]
      # @param client [String, nil]
      # @return [Array<String>]
      def resolve_path(path_config, client: nil)
        Array(path_config).map do |seg|
          case seg
          when Proc
            # Support lambdas that accept (config) or (config, client)
            if seg.arity >= 2
              seg.call(Verikloak::Pundit.config, client).to_s
            else
              seg.call(Verikloak::Pundit.config).to_s
            end
          else
            seg.to_s
          end
        end
      end

      # Resolve resource roles based on configured permission scope.
      # @return [Array<String>]
      def resource_roles_scope
        case Verikloak::Pundit.config.permission_role_scope&.to_sym
        when :all_resources
          resource_roles_all_clients
        else
          resource_roles
        end
      end

      # Collect resource roles from all clients under resource_access.
      # @return [Array<String>]
      def resource_roles_all_clients
        access = claims['resource_access']
        return [] unless access.is_a?(Hash)

        # Bypass configured path lambda (which targets the default client)
        # and gather roles from all clients explicitly.
        access.values.flat_map { |entry| Array(entry['roles']) }
      end
    end
  end
end
