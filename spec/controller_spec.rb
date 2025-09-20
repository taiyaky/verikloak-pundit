# frozen_string_literal: true

require "spec_helper"

class FakeRequest < Struct.new(:env); end

class FakeController
  include Verikloak::Pundit::Controller

  def initialize(env)
    @request = FakeRequest.new(env)
  end

  def request
    @request
  end
end

RSpec.describe Verikloak::Pundit::Controller do
  describe ".included" do
    def build_controller_class
      Class.new do
        class << self
          attr_reader :helper_method_calls

          def helper_method(*args)
            (@helper_method_calls ||= []) << args
          end
        end

        def self.name
          "HelperMethodTestController"
        end
      end
    end

    it "registers verikloak_claims helper when enabled" do
      previous_value = Verikloak::Pundit.config.expose_helper_method
      begin
        Verikloak::Pundit.configure { |c| c.expose_helper_method = true }
        klass = build_controller_class
        klass.include(described_class)

        expect(klass.helper_method_calls).to include([:verikloak_claims])
      ensure
        Verikloak::Pundit.configure { |c| c.expose_helper_method = previous_value }
      end
    end

    it "skips helper registration when disabled" do
      previous_value = Verikloak::Pundit.config.expose_helper_method
      begin
        Verikloak::Pundit.configure { |c| c.expose_helper_method = false }
        klass = build_controller_class
        klass.include(described_class)

        expect(klass.helper_method_calls).to be_nil
      ensure
        Verikloak::Pundit.configure { |c| c.expose_helper_method = previous_value }
      end
    end
  end

  it "builds a UserContext from env and exposes claims" do
    begin
      Verikloak::Pundit.configure do |c|
        c.env_claims_key = "verikloak.user"
      end
      claims = { "sub" => "xyz", "realm_access" => { "roles" => ["a"] } }
      env = { "verikloak.user" => claims }
      controller = FakeController.new(env)

      ctx = controller.pundit_user
      expect(ctx).to be_a(Verikloak::Pundit::UserContext)
      expect(ctx.sub).to eq("xyz")
      expect(controller.verikloak_claims).to eq(claims)
    ensure
      Verikloak::Pundit.configure { |c| c.env_claims_key = "verikloak.user" }
    end
  end
end
