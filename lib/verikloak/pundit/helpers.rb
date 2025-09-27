# frozen_string_literal: true

module Verikloak
  module Pundit
    # Helpers expose convenient delegations to the policy `user`.
    #
    # @deprecated Use {Delegations} directly instead. This module will be removed in v1.0.0.
    module Helpers
      include Delegations

      # Warn consumers when the deprecated helper module is included.
      #
      # @param base [Module] module or class including this helper
      # @return [void]
      def self.included(base)
        warn '[DEPRECATED] Verikloak::Pundit::Helpers is deprecated. ' \
             'Include Verikloak::Pundit::Delegations directly instead. ' \
             'This will be removed in v1.0.0.'
        super
      end
    end
  end
end
