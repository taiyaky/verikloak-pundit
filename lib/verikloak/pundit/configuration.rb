# frozen_string_literal: true

module Verikloak
  module Pundit
    # Runtime configuration for verikloak-pundit.
    #
    # @!attribute resource_client
    #   @return [String] default Keycloak resource client used for resource roles
    # @!attribute role_map
    #   @return [Hash{Symbol=>Symbol,String,nil}] mapping from roles to
    #     permissions; a nil value explicitly revokes the role's implicit
    #     permission
    # @!attribute env_claims_key
    #   @return [String] Rack env key where claims are stored (when using verikloak/verikloak-rails)
    # @!attribute realm_roles_path
    #   @return [Array<String,Proc>] path inside JWT claims to reach realm roles
    # @!attribute resource_roles_path
    #   @return [Array<String,Proc>] path inside JWT claims to reach resource roles
    # @!attribute permission_role_scope
    #   @return [Symbol] :default_resource or :all_resources for permission mapping scope
    # @!attribute permission_resource_clients
    #   @return [Array<String>, nil] list of resource clients allowed when
    #     {#permission_role_scope} is `:all_resources`. `nil` permits every client.
    # @!attribute strict_permissions
    #   @return [Boolean] when true, `has_permission?` only grants permissions that
    #     appear as values in {#role_map}; unmapped role names no longer act as
    #     implicit permissions
    # @!attribute expose_helper_method
    #   @return [Boolean] whether `verikloak_claims` is exposed to Rails views
    class Configuration
      attr_accessor :env_claims_key,
                    :realm_roles_path, :resource_roles_path,
                    :permission_role_scope, :permission_resource_clients,
                    :strict_permissions, :expose_helper_method

      attr_reader :role_map
      attr_writer :resource_client

      # Set the role map, normalizing keys to symbols for consistent lookup.
      # Values must be Symbols, Strings, or nil (an explicit nil revokes the
      # role's implicit permission); anything else raises at assignment time
      # so misconfiguration surfaces at boot instead of as silently missing
      # permissions.
      #
      # @param value [Hash]
      # @return [void]
      # @raise [ArgumentError] when a value is neither Symbol, String, nor nil
      def role_map=(value)
        @role_map = normalize_role_map(value)
      end

      # Returns the resource client, falling back to ENV['KEYCLOAK_RESOURCE_CLIENT'] if not set.
      #
      # @return [String]
      def resource_client
        @resource_client || ENV.fetch('KEYCLOAK_RESOURCE_CLIENT', 'rails-api')
      end

      # Build a new configuration populated with default values.
      def initialize
        @resource_client   = nil # Falls back to ENV['KEYCLOAK_RESOURCE_CLIENT'] or 'rails-api'
        @role_map          = {} # e.g., { admin: :manage_all }
        @env_claims_key    = 'verikloak.user'
        @realm_roles_path  = %w[realm_access roles]
        # The lambda receives (config, client) so that an explicitly requested
        # client (e.g. resource_role?(:other, :role)) resolves to that client's
        # entry instead of always falling back to the default resource client.
        @resource_roles_path = ['resource_access', ->(cfg, client) { client || cfg.resource_client }, 'roles']
        # :default_resource (realm + default client), :all_resources (realm + all clients)
        @permission_role_scope = :default_resource
        @permission_resource_clients = nil
        @strict_permissions = false
        @expose_helper_method = true
      end

      # Duplicate the configuration via Ruby's `dup`/`clone`, ensuring the new
      # instance receives freshly-copied (and unfrozen) nested state.
      #
      # @param other [Configuration]
      def initialize_copy(other)
        super
        # Copy the raw instance variable, not the getter, to preserve ENV fallback behavior
        @resource_client = deep_dup(other.instance_variable_get(:@resource_client))
        @role_map = deep_dup(other.role_map)
        @env_claims_key = deep_dup(other.env_claims_key)
        @realm_roles_path = deep_dup(other.realm_roles_path)
        @resource_roles_path = deep_dup(other.resource_roles_path)
        @permission_role_scope = other.permission_role_scope
        @permission_resource_clients = deep_dup(other.permission_resource_clients)
        @strict_permissions = other.strict_permissions
        @expose_helper_method = other.expose_helper_method
      end

      # Freeze the configuration and its nested structures to prevent runtime
      # mutations once it is published to the global state. Returns `self` to
      # allow chaining inside callers.
      #
      # @return [Configuration]
      def finalize!
        @resource_client = freeze_string(@resource_client)
        @env_claims_key = freeze_string(@env_claims_key)
        @role_map = deep_dup(@role_map).freeze
        @realm_roles_path = deep_dup(@realm_roles_path).freeze
        @resource_roles_path = deep_dup(@resource_roles_path).freeze
        @permission_resource_clients = freeze_permission_clients(@permission_resource_clients)
        # Coerce flags to strict booleans based on truthiness
        @strict_permissions = @strict_permissions ? true : false
        @expose_helper_method = @expose_helper_method ? true : false
        freeze
      end

      private

      # Normalize role_map keys to symbols and validate value types.
      #
      # @param map [Hash, nil]
      # @return [Hash]
      # @raise [ArgumentError] when a value is neither Symbol, String, nor nil
      def normalize_role_map(map)
        return {} unless map.is_a?(Hash)

        map.each do |key, value|
          next if value.nil? || value.is_a?(Symbol) || value.is_a?(String)

          raise ArgumentError,
                "role_map value for #{key.inspect} must be a Symbol, a String, " \
                "or nil (explicit revocation); got #{value.class}"
        end
        map.transform_keys(&:to_sym)
      end

      # Duplicate and freeze a string value, returning `nil` when appropriate.
      #
      # @param value [String, nil]
      # @return [String, nil]
      def freeze_string(value)
        return nil if value.nil?

        deep_dup(value).freeze
      end

      # Deep duplicate any object, handling nested structures recursively.
      #
      # @param value [Object] The value to duplicate
      # @return [Object] A deep copy of the value
      def deep_dup(value)
        case value
        when nil
          nil
        when Hash
          value.each_with_object({}) do |(key, element), copy|
            copy[deep_dup(key)] = deep_dup(element)
          end
        when Array
          value.map { |element| deep_dup(element) }
        when String
          value.dup
        else
          duplicable?(value) ? value.dup : value
        end
      end

      # Check whether a value can be safely duplicated using `dup`.
      #
      # @param value [Object]
      # @return [Boolean]
      def duplicable?(value)
        return false if value.nil?
        return false if [true, false].include?(value)
        return false if value.is_a?(Symbol) || value.is_a?(Numeric) || value.is_a?(Proc)

        value.respond_to?(:dup)
      end

      # Normalize and freeze the configured permission clients list.
      #
      # @param value [Array<String, Symbol>, nil]
      # @return [Array<String>, nil]
      def freeze_permission_clients(value)
        array = deep_dup(value)
        return nil if array.nil?

        array.compact.map(&:to_s).uniq.freeze
      end
    end
  end
end
