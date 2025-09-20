# frozen_string_literal: true

require 'rails/generators'

module Verikloak
  module Pundit
    module Generators
      # Generator to install initializer and base ApplicationPolicy template.
      class InstallGenerator < ::Rails::Generators::Base
        source_root File.expand_path('templates', __dir__)
        desc 'Creates Verikloak Pundit initializer and a base ApplicationPolicy (optional).'

        # Skip creating application_policy.rb
        # @return [Boolean]
        class_option :skip_policy, type: :boolean, default: false, desc: 'Do not create application_policy.rb'

        # Create the initializer file under config/initializers.
        def create_initializer
          template 'initializer.rb', 'config/initializers/verikloak_pundit.rb'
        end

        # Create app/policies/application_policy.rb unless present.
        def create_application_policy
          return if options[:skip_policy]

          dest = 'app/policies/application_policy.rb'
          return if File.exist?(dest)

          template 'application_policy.rb', dest
        end
      end
    end
  end
end
