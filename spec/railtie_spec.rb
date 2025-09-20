# frozen_string_literal: true
require "spec_helper"

RSpec.describe 'Verikloak::Pundit::Railtie integration' do
  it "registers on_load(:action_controller) and includes Controller" do
    # Stub Rails::Railtie.initializer to execute immediately
    module Rails; end
    class Rails::Railtie
      def self.initializer(_name, &block)
        block.call
      end
    end

    # Stub ActiveSupport.on_load to capture the block via globals
    module ActiveSupport; end
    def ActiveSupport.on_load(sym, &blk)
      $as_on_load_sym = sym
      $as_on_load_blk = blk
    end

    # Avoid requiring real rails/railtie by marking it as loaded
    $LOADED_FEATURES << 'rails/railtie'

    # Load the railtie file explicitly
    load File.expand_path('../lib/verikloak/pundit/railtie.rb', __dir__)

    expect($as_on_load_sym).to eq(:action_controller)
    blk = $as_on_load_blk

    # Simulate ActionController load by applying the captured block to a dummy class
    dummy = Class.new
    dummy.class_eval(&blk)
    expect(dummy.included_modules).to include(Verikloak::Pundit::Controller)
  ensure
    $as_on_load_sym = nil
    $as_on_load_blk = nil
  end
end
