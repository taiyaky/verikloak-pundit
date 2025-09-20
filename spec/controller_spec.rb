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
