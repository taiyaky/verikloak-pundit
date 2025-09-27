# frozen_string_literal: true

# Verikloak::Pundit provides Pundit integration over Keycloak claims.
require_relative 'pundit/version'
require_relative 'pundit/configuration'
require_relative 'pundit/role_mapper'
require_relative 'pundit/delegations'
require_relative 'pundit/claim_utils'
require_relative 'pundit/user_context'
require_relative 'pundit/helpers'
require_relative 'pundit/controller'
require_relative 'pundit/policy'
require_relative 'pundit/railtie' if defined?(Rails::Railtie)

module Verikloak
  # Pundit integration namespace
  module Pundit
    class << self
      # Configure the library at runtime.
      #
      # @yield [Configuration] Yields the configuration instance for mutation.
      # @return [Configuration] the current configuration after applying changes
      def configure
        new_config = nil
        config_mutex.synchronize do
          current = @config&.dup || Configuration.new
          yield current if block_given?
          new_config = current.finalize!
          @config = new_config
        end
        new_config
      end

      # Access the current configuration without mutating it.
      #
      # @return [Configuration]
      def config
        config_mutex.synchronize do
          @config ||= Configuration.new.finalize!
        end
      end

      # Reset configuration to defaults. Useful for test suites.
      #
      # @return [void]
      def reset!
        config_mutex.synchronize do
          @config = nil
        end
      end

      private

      # Mutex protecting configuration reads/writes to maintain thread safety.
      #
      # @return [Mutex]
      def config_mutex
        @config_mutex ||= Mutex.new
      end
    end
  end
end
