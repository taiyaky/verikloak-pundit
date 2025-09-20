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
    # @!attribute expose_helper_method
    #   @return [Boolean] whether to register `verikloak_claims` as a Rails helper method
    class Configuration
      attr_accessor :resource_client, :role_map, :env_claims_key,
                    :realm_roles_path, :resource_roles_path,
                    :permission_role_scope, :expose_helper_method

      def initialize(copy_from = nil)
        if copy_from
          initialize_from(copy_from)
        else
          initialize_defaults
        end
      end

      # Create a deep-ish copy that can be safely mutated without affecting the
      # source configuration. `dup` is overridden so the object returned from
      # `Verikloak::Pundit.config.dup` behaves as expected.
      def dup
        self.class.new(self)
      end

      def initialize_copy(other)
        super
        initialize_from(other)
      end

      # Freeze the configuration and its nested structures to prevent runtime
      # mutations once it is published to the global state. Returns `self` to
      # allow chaining inside callers.
      #
      # @return [Configuration]
      def finalize!
        @resource_client = freeze_string(@resource_client)
        @env_claims_key = freeze_string(@env_claims_key)
        @role_map = dup_hash(@role_map).freeze
        @realm_roles_path = dup_array(@realm_roles_path).freeze
        @resource_roles_path = dup_array(@resource_roles_path).freeze
        @expose_helper_method = @expose_helper_method ? true : false
        freeze
      end

      private

      def initialize_defaults
        @resource_client   = 'rails-api'
        @role_map          = {} # e.g., { admin: :manage_all }
        @env_claims_key    = 'verikloak.user'
        @realm_roles_path  = %w[realm_access roles]
        # rubocop:disable Style/SymbolProc -- we need a Proc object here, not block pass
        @resource_roles_path = ['resource_access', ->(cfg) { cfg.resource_client }, 'roles']
        # rubocop:enable Style/SymbolProc
        # :default_resource (realm + default client), :all_resources (realm + all clients)
        @permission_role_scope = :default_resource
        @expose_helper_method = true
      end

      def initialize_from(other)
        @resource_client = dup_string(other.resource_client)
        @role_map = dup_hash(other.role_map)
        @env_claims_key = dup_string(other.env_claims_key)
        @realm_roles_path = dup_array(other.realm_roles_path)
        @resource_roles_path = dup_array(other.resource_roles_path)
        @permission_role_scope = other.permission_role_scope
        @expose_helper_method = other.expose_helper_method
      end

      def freeze_string(value)
        return nil if value.nil?

        dup_string(value).freeze
      end

      def dup_hash(value)
        return nil if value.nil?

        copy = value.dup
        copy.each do |key, element|
          copy[key] =
            case element
            when Hash
              dup_hash(element)
            when Array
              dup_array(element)
            when String
              dup_string(element)
            else
              duplicable?(element) ? element.dup : element
            end
        end
        copy
      end

      def dup_string(value)
        return nil if value.nil?

        value.dup
      end

      def dup_array(value)
        return nil if value.nil?

        copy = value.dup
        return copy unless copy.respond_to?(:map)

        copy.map do |element|
          case element
          when Hash
            dup_hash(element)
          when Array
            dup_array(element)
          when String
            dup_string(element)
          else
            duplicable?(element) ? element.dup : element
          end
        end
      end

      def duplicable?(value)
        case value
        when nil, true, false, Symbol, Numeric, Proc
          false
        else
          value.respond_to?(:dup)
        end
      end
    end
  end
end
