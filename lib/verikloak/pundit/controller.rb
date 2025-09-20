# frozen_string_literal: true

module Verikloak
  module Pundit
    # Rails controller mixin providing `pundit_user` and claims accessor.
    module Controller
      # Hook used by Rails to include helper methods in views when available.
      # @param base [Class]
      def self.included(base)
        base.helper_method :verikloak_claims if base.respond_to?(:helper_method)
      end

      # Pundit hook returning the UserContext built from Rack env claims.
      # @return [UserContext]
      def pundit_user
        Verikloak::Pundit::UserContext.from_env(request.env)
      end

      # Access raw Verikloak claims from Rack env.
      # @return [Hash, nil]
      def verikloak_claims
        request.env[Verikloak::Pundit.config.env_claims_key]
      end
    end
  end
end
