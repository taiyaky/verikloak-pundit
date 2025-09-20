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
    end
  end
end
