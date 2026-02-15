# frozen_string_literal: true

module Verikloak
  module Pundit
    # Helpers for coercing incoming claims payloads into safe Hashes.
    module ClaimUtils
      module_function

      # Normalize incoming claims to a Hash to guard against odd payload types.
      #
      # @param claims [Object]
      # @return [Hash]
      def normalize(claims)
        return {} if claims.nil?
        return claims if claims.is_a?(Hash)

        if claims.respond_to?(:to_hash)
          coerced = claims.to_hash
          return coerced if coerced.is_a?(Hash)
        end

        {}
      rescue StandardError => e
        warn "[Verikloak::Pundit] ClaimUtils.normalize failed: #{e.class}: #{e.message}" if $DEBUG
        {}
      end
    end
  end
end
