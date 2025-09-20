# frozen_string_literal: true

require "spec_helper"

RSpec.describe Verikloak::Pundit::Configuration do
  it "has sensible defaults" do
    cfg = described_class.new
    expect(cfg.resource_client).to eq("rails-api")
    expect(cfg.role_map).to eq({})
    expect(cfg.env_claims_key).to eq("verikloak.user")
    expect(cfg.realm_roles_path).to eq(%w[realm_access roles])
    expect(cfg.resource_roles_path).to be_a(Array)
    expect(cfg.permission_role_scope).to eq(:default_resource)
  end

  it "is configurable via Verikloak::Pundit.configure" do
    begin
      result = Verikloak::Pundit.configure do |c|
        c.resource_client = "api"
        c.role_map = { admin: :all }
        c.permission_role_scope = :all_resources
      end
      expect(result).to be_a(described_class)
      expect(result).to be_frozen
      expect(result.resource_client).to be_frozen
      expect(result.role_map).to be_frozen
      expect(result.env_claims_key).to be_frozen
      expect(Verikloak::Pundit.config.resource_client).to eq("api")
      expect(Verikloak::Pundit.config.role_map).to eq({ admin: :all })
      expect(Verikloak::Pundit.config.permission_role_scope).to eq(:all_resources)
    ensure
      Verikloak::Pundit.configure do |c|
        c.resource_client = "rails-api"
        c.role_map = {}
        c.permission_role_scope = :default_resource
      end
    end
  end

  it "provides unfrozen copies when reconfiguring" do
    begin
      Verikloak::Pundit.configure do |c|
        c.resource_client = "api"
        c.role_map = { admin: :all }
      end

      Verikloak::Pundit.configure do |c|
        expect(c).not_to be_frozen
        expect(c.role_map).not_to be_frozen
        c.role_map[:reader] = :read
      end

      expect(Verikloak::Pundit.config.role_map).to eq({ admin: :all, reader: :read })
    ensure
      Verikloak::Pundit.configure do |c|
        c.resource_client = "rails-api"
        c.role_map = {}
      end
    end
  end
end

