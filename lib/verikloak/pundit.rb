# frozen_string_literal: true

# Verikloak::Pundit provides Pundit integration over Keycloak claims.
require_relative 'pundit/version'
require_relative 'pundit/configuration'
require_relative 'pundit/role_mapper'
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
        @config ||= Configuration.new
        yield @config if block_given?
        @config
      end

      # Access the current configuration without mutating it.
      #
      # @return [Configuration]
      def config
        @config ||= Configuration.new
      end
    end
  end
end
