# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Verikloak::Pundit::Controller do
  after do
    Verikloak::Pundit.reset!
  end

  let(:controller_class) do
    Class.new do
      include Verikloak::Pundit::Controller

      attr_reader :request

      def initialize(env)
        @request = Struct.new(:env).new(env)
      end
    end
  end

  describe '.included' do
    it 'registers ViewHelpers when the base supports helper' do
      klass = Class.new do
        class << self
          attr_reader :helper_calls

          def helper(mod)
            (@helper_calls ||= []) << mod
          end
        end
      end
      klass.include(described_class)

      expect(klass.helper_calls).to eq([Verikloak::Pundit::Controller::ViewHelpers])
    end

    it 'skips helper registration when the base has no helper support' do
      klass = Class.new
      expect { klass.include(described_class) }.not_to raise_error
    end
  end

  describe Verikloak::Pundit::Controller::ViewHelpers do
    let(:view_class) do
      Class.new do
        include Verikloak::Pundit::Controller::ViewHelpers

        attr_reader :controller

        def initialize(controller)
          @controller = controller
        end
      end
    end

    it 'evaluates expose_helper_method at call time' do
      claims = { 'sub' => 'xyz' }
      controller = controller_class.new({ 'verikloak.user' => claims })
      view = view_class.new(controller)

      Verikloak::Pundit.configure { |c| c.expose_helper_method = true }
      expect(view.verikloak_claims).to eq(claims)

      # Flipping the flag after the controller was loaded takes effect immediately
      Verikloak::Pundit.configure { |c| c.expose_helper_method = false }
      expect(view.verikloak_claims).to be_nil
    end

    it 'returns nil when the view has no controller' do
      Verikloak::Pundit.configure { |c| c.expose_helper_method = true }
      view = view_class.new(nil)

      expect(view.verikloak_claims).to be_nil
    end
  end

  it 'builds a UserContext from env and exposes claims' do
    claims = { 'sub' => 'xyz', 'realm_access' => { 'roles' => ['a'] } }
    env = { 'verikloak.user' => claims }
    controller = controller_class.new(env)

    ctx = controller.pundit_user
    expect(ctx).to be_a(Verikloak::Pundit::UserContext)
    expect(ctx.sub).to eq('xyz')
    expect(controller.verikloak_claims).to eq(claims)
  end

  it 'memoizes pundit_user per controller instance' do
    controller = controller_class.new({ 'verikloak.user' => { 'sub' => 'xyz' } })

    expect(controller.pundit_user).to equal(controller.pundit_user)
  end
end
