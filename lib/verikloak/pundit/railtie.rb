# frozen_string_literal: true

require 'rails/railtie'

module Verikloak
  module Pundit
    # Railtie to auto-include Controller helpers in Rails.
    class Railtie < ::Rails::Railtie
      # Include controller helpers into ActionController when it loads.
      initializer 'verikloak_pundit.controller' do
        ActiveSupport.on_load(:action_controller) do
          include Verikloak::Pundit::Controller
        end
      end

      # Synchronize configuration with verikloak-rails when available.
      # Runs after verikloak-rails configuration is applied.
      initializer 'verikloak_pundit.sync_configuration', after: 'verikloak.configure' do
        Verikloak::Pundit::Railtie.sync_with_verikloak_rails if defined?(Verikloak::Rails)
      end

      class << self
        # Sync env_claims_key with verikloak-rails configuration.
        # Only applies if env_claims_key has not been explicitly set.
        #
        # @return [void]
        def sync_with_verikloak_rails
          return unless Verikloak::Rails.respond_to?(:config)

          rails_config = Verikloak::Rails.config
          return unless rails_config.respond_to?(:user_env_key) && rails_config.user_env_key

          current_key = Verikloak::Pundit.config.env_claims_key
          return unless current_key == 'verikloak.user'

          # Use configure to properly update frozen config
          Verikloak::Pundit.configure do |c|
            c.env_claims_key = rails_config.user_env_key
          end
        rescue StandardError => e
          warn "[verikloak-pundit] Failed to sync with verikloak-rails: #{e.message}"
        end
      end
    end
  end
end
