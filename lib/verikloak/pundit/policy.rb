# frozen_string_literal: true

module Verikloak
  module Pundit
    # Policy mixin to delegate common helpers to the `user` context.
    #
    # @deprecated Use {Delegations} directly instead. This module will be removed in v1.0.0.
    module Policy
      # Warn consumers when the deprecated policy mixin is included.
      #
      # @param base [Module] module or class including this policy mixin
      # @return [void]
      def self.included(base)
        warn '[DEPRECATED] Verikloak::Pundit::Policy is deprecated. ' \
             'Include Verikloak::Pundit::Delegations directly instead. ' \
             'This will be removed in v1.0.0.'
        base.extend(ClassMethods)
        super
      end

      # Placeholder for future class-level helpers
      module ClassMethods; end

      include Delegations
    end
  end
end
