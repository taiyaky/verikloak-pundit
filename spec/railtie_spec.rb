# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Verikloak::Pundit::Railtie' do
  after do
    Verikloak::Pundit.reset!
    Verikloak::Pundit.send(:remove_const, :Railtie) if Verikloak::Pundit.const_defined?(:Railtie, false)
  end

  # Load railtie.rb against a stubbed Rails::Railtie that records
  # `initializer` registrations, and return those registrations.
  #
  # @return [Array<Array(String, Hash, Proc)>]
  def load_railtie
    initializer_calls = []
    railtie_base = Class.new do
      define_singleton_method(:initializer) do |name, **options, &block|
        initializer_calls << [name, options, block]
      end
    end
    stub_const('Rails', Module.new)
    stub_const('Rails::Railtie', railtie_base)
    stub_require('rails/railtie')

    Verikloak::Pundit.send(:remove_const, :Railtie) if Verikloak::Pundit.const_defined?(:Railtie, false)
    load File.expand_path('../lib/verikloak/pundit/railtie.rb', __dir__)
    initializer_calls
  end

  it 'registers on_load(:action_controller) and includes Controller' do
    calls = load_railtie
    _name, _options, block = calls.find { |(name, *)| name == 'verikloak_pundit.controller' }
    expect(block).not_to be_nil

    captured_sym = nil
    captured_blk = nil
    active_support = Module.new
    active_support.define_singleton_method(:on_load) do |sym, &blk|
      captured_sym = sym
      captured_blk = blk
    end
    stub_const('ActiveSupport', active_support)

    block.call
    expect(captured_sym).to eq(:action_controller)

    dummy = Class.new
    dummy.class_eval(&captured_blk)
    expect(dummy.included_modules).to include(Verikloak::Pundit::Controller)
  end

  it "registers the sync initializer after verikloak-rails' configure step" do
    calls = load_railtie
    _name, options, block = calls.find { |(name, *)| name == 'verikloak_pundit.sync_configuration' }
    expect(options[:after]).to eq('verikloak.configure')
    expect(block).not_to be_nil
  end

  describe '.sync_with_verikloak_rails' do
    before { load_railtie }

    def stub_verikloak_rails(user_env_key: nil, &user_env_key_impl)
      rails_config = Object.new
      impl = user_env_key_impl || -> { user_env_key }
      rails_config.define_singleton_method(:user_env_key, &impl)

      verikloak_rails = Module.new
      verikloak_rails.define_singleton_method(:config) { rails_config }
      stub_const('Verikloak::Rails', verikloak_rails)
      rails_config
    end

    it 'adopts user_env_key from verikloak-rails when env_claims_key is at its default' do
      stub_verikloak_rails(user_env_key: 'custom.claims')

      Verikloak::Pundit::Railtie.sync_with_verikloak_rails

      expect(Verikloak::Pundit.config.env_claims_key).to eq('custom.claims')
    end

    it 'keeps an explicitly configured env_claims_key' do
      stub_verikloak_rails(user_env_key: 'custom.claims')
      Verikloak::Pundit.configure { |c| c.env_claims_key = 'mine.claims' }

      Verikloak::Pundit::Railtie.sync_with_verikloak_rails

      expect(Verikloak::Pundit.config.env_claims_key).to eq('mine.claims')
    end

    it 'does nothing when verikloak-rails has no user_env_key' do
      stub_verikloak_rails(user_env_key: nil)

      Verikloak::Pundit::Railtie.sync_with_verikloak_rails

      expect(Verikloak::Pundit.config.env_claims_key).to eq('verikloak.user')
    end

    it 'warns and keeps the current configuration when the sync raises' do
      stub_verikloak_rails { raise 'boom' }

      expect { Verikloak::Pundit::Railtie.sync_with_verikloak_rails }
        .to output(/Failed to sync with verikloak-rails: boom/).to_stderr

      expect(Verikloak::Pundit.config.env_claims_key).to eq('verikloak.user')
    end
  end
end
