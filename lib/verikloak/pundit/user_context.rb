# frozen_string_literal: true

require 'set'

module Verikloak
  module Pundit
    # Lightweight wrapper around Keycloak claims for Pundit policies.
    class UserContext
      # JWT claim keys used internally
      CLAIM_SUB = 'sub'
      CLAIM_EMAIL = 'email'
      CLAIM_PREFERRED_USERNAME = 'preferred_username'
      CLAIM_RESOURCE_ACCESS = 'resource_access'
      CLAIM_ROLES = 'roles'

      attr_reader :claims, :resource_client, :config

      # Create a new user context from JWT claims.
      #
      # @param claims [Hash] JWT claims issued by Keycloak
      # @param resource_client [String] default resource client name for resource roles
      # @param config [Verikloak::Pundit::Configuration] configuration snapshot to use
      def initialize(claims, resource_client: nil, config: nil)
        @config = config || Verikloak::Pundit.config
        @claims = ClaimUtils.normalize(claims)
        @resource_client = (resource_client || @config.resource_client).to_s
      end

      # Subject identifier from claims.
      # @return [String, nil]
      def sub
        claims[CLAIM_SUB]
      end

      # Email or preferred username from claims.
      # @return [String, nil]
      def email
        claims[CLAIM_EMAIL] || claims[CLAIM_PREFERRED_USERNAME]
      end

      # Realm-level roles from claims based on configuration path.
      # @return [Array<String>]
      def realm_roles
        @realm_roles ||= begin
          path = resolve_path(config.realm_roles_path)
          Array(claims.dig(*path)).map(&:to_s).uniq.freeze
        end
      end

      # Resource-level roles for a given client from claims based on configuration path.
      #
      # @param client [String] resource client id (defaults to configured resource_client)
      # @return [Array<String>]
      def resource_roles(client = resource_client)
        client = client.to_s
        (@resource_roles_cache ||= {})[client] ||= begin
          path = resolve_path(config.resource_roles_path, client: client)
          Array(claims.dig(*path)).map(&:to_s).uniq.freeze
        end
      end

      # Check whether the user has a realm role.
      #
      # @param role [String, Symbol]
      # @return [Boolean]
      def has_role?(role) # rubocop:disable Naming/PredicatePrefix
        realm_roles.include?(role.to_s)
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
        resource_roles(client).include?(role.to_s)
      end

      # Check whether the user has a mapped permission.
      #
      # Uses realm roles and resource roles depending on
      # {Configuration#permission_role_scope}.
      #
      # @param perm [String, Symbol] permission to check
      # @return [Boolean]
      def has_permission?(perm) # rubocop:disable Naming/PredicatePrefix
        permission_set.include?(normalize_to_symbol(perm))
      end

      # Build a user context from Rack env using configured claims key.
      #
      # @param env [Hash] Rack environment
      # @return [UserContext]
      def self.from_env(env)
        config = Verikloak::Pundit.config
        claims = env&.fetch(config.env_claims_key, nil)
        new(claims, config: config)
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
              seg.call(config, client).to_s
            else
              seg.call(config).to_s
            end
          else
            seg.to_s
          end
        end
      end

      # Resolve resource roles based on configured permission scope.
      # @return [Array<String>]
      def resource_roles_scope
        case config.permission_role_scope&.to_sym
        when :all_resources
          resource_roles_all_clients
        else
          resource_roles
        end
      end

      # Collect resource roles from all clients under resource_access.
      # @return [Array<String>]
      def resource_roles_all_clients
        @resource_roles_all_clients ||= begin
          access = claims[CLAIM_RESOURCE_ACCESS]
          if access.is_a?(Hash)
            roles = access.each_with_object([]) do |(client_id, entry), acc|
              next unless permission_client_allowed?(client_id)

              acc.concat(Array(entry[CLAIM_ROLES]))
            end
            roles.map(&:to_s).uniq.freeze
          else
            [].freeze
          end
        end
      end

      # Check whether the given client is allowed for permission scope.
      #
      # @param client_id [String]
      # @return [Boolean]
      def permission_client_allowed?(client_id)
        whitelist = config.permission_resource_clients
        return true if whitelist.nil?

        whitelist.include?(client_id.to_s)
      end

      # Cached permission lookup set combining realm and configured resource scopes.
      # @return [Set<Symbol>]
      def permission_set
        @permission_set ||= build_permission_set.freeze
      end

      # Build the permission set from roles and role mappings.
      # @return [Set<Symbol>]
      def build_permission_set
        roles = realm_roles + resource_roles_scope
        permissions = Set.new

        roles.each do |role|
          mapped_permission = RoleMapper.map(role, config)
          symbol_permission = normalize_to_symbol(mapped_permission)
          permissions << symbol_permission if symbol_permission
        end

        permissions
      end

      # Normalize a value to a symbol, handling various types safely.
      # @param value [Object] The value to convert to a symbol
      # @return [Symbol, nil] The symbol representation, or nil if not convertible
      def normalize_to_symbol(value)
        case value
        when Symbol
          value
        when String
          return nil if value.empty?

          value.to_sym
        else
          if value.respond_to?(:to_sym)
            value.to_sym
          elsif value.respond_to?(:to_s)
            text = value.to_s
            return nil if text.empty?

            text.to_sym
          end
        end
      rescue StandardError
        nil
      end
    end
  end
end
