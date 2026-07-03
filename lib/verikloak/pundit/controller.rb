# frozen_string_literal: true

module Verikloak
  module Pundit
    # Rails controller mixin providing `pundit_user` and claims accessor.
    module Controller
      # View-facing helpers registered on helper-capable controllers.
      #
      # Exposure is decided at call time (not include time) so that
      # `expose_helper_method` set in `config/initializers` is honored even
      # when ActionController loads before application initializers run.
      module ViewHelpers
        # Access raw Verikloak claims from the controller, or nil when
        # exposure to views is disabled via configuration.
        #
        # @return [Hash, nil]
        def verikloak_claims
          return nil unless Verikloak::Pundit.config.expose_helper_method

          controller&.verikloak_claims
        end
      end

      # Hook used by Rails to register view helpers when available.
      # @param base [Class]
      def self.included(base)
        base.helper(ViewHelpers) if base.respond_to?(:helper)
      end

      # Pundit hook returning the UserContext built from Rack env claims.
      # Memoized to avoid creating multiple instances per request.
      # @return [UserContext]
      def pundit_user
        @pundit_user ||= Verikloak::Pundit::UserContext.from_env(request.env)
      end

      # Access raw Verikloak claims from Rack env.
      # @return [Hash, nil]
      def verikloak_claims
        request.env[Verikloak::Pundit.config.env_claims_key]
      end
    end
  end
end
