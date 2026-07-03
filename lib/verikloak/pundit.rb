# frozen_string_literal: true

require 'monitor'

# Verikloak::Pundit provides Pundit integration over Keycloak claims.
require_relative 'pundit/version'
require_relative 'pundit/configuration'
require_relative 'pundit/role_mapper'
require_relative 'pundit/delegations'
require_relative 'pundit/claim_utils'
require_relative 'pundit/user_context'
require_relative 'pundit/controller'
require_relative 'pundit/railtie' if defined?(Rails::Railtie)

module Verikloak
  # Pundit integration namespace
  module Pundit
    # Eagerly-initialized lock to protect configuration reads/writes.
    # Using ||= inside a method is NOT thread-safe — two threads can race
    # past the nil-check and create separate lock instances. A reentrant
    # Monitor (rather than Mutex) allows `config` to be read from within a
    # `configure` block without raising ThreadError.
    @config_lock = Monitor.new

    class << self
      # Configure the library at runtime.
      #
      # @yield [Configuration] Yields the configuration instance for mutation.
      # @return [Configuration] the current configuration after applying changes
      def configure
        new_config = nil
        config_lock.synchronize do
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
        config_lock.synchronize do
          @config ||= Configuration.new.finalize!
        end
      end

      # Reset configuration to defaults. Useful for test suites.
      #
      # @return [void]
      def reset!
        config_lock.synchronize do
          @config = nil
        end
      end

      private

      # Reentrant lock protecting configuration reads/writes.
      # Eagerly initialized at load time (see module body above).
      #
      # @return [Monitor]
      attr_reader :config_lock
    end
  end
end
