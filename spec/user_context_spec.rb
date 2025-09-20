# frozen_string_literal: true

require "spec_helper"

RSpec.describe Verikloak::Pundit::UserContext do
  let(:claims) do
    {
      "sub" => "abc",
      "email" => "u@example.com",
      "realm_access" => { "roles" => ["admin", "reader"] },
      "resource_access" => { "rails-api" => { "roles" => ["editor"] } }
    }
  end

  it "reads realm roles" do
    ctx = described_class.new(claims)
    expect(ctx.has_role?(:admin)).to be true
    expect(ctx.in_group?("reader")).to be true
  end

  it "reads resource roles" do
    ctx = described_class.new(claims)
    expect(ctx.resource_role?(:'rails-api', :editor)).to be true
  end

  it "respects configurable resource_roles_path with client override" do
    begin
      # Configure path to accept (config, client) for dynamic segment
      Verikloak::Pundit.configure do |c|
        c.resource_client = "rails-api"
        c.resource_roles_path = [
          "resource_access",
          ->(cfg, client) { client || cfg.resource_client },
          "roles"
        ]
      end

      test_claims = {
        "resource_access" => {
          "another" => { "roles" => ["writer"] }
        }
      }
      ctx = described_class.new(test_claims)
      expect(ctx.resource_role?(:another, :writer)).to be true
    ensure
      # restore defaults to avoid leaking config between examples
      Verikloak::Pundit.configure do |c|
        c.resource_client = "rails-api"
        c.resource_roles_path = ["resource_access", ->(cfg){ cfg.resource_client }, "roles"]
      end
    end
  end

  it "maps permissions from realm and resource roles" do
    begin
      Verikloak::Pundit.configure do |c|
        c.role_map = {
          admin: :manage_all,
          editor: :write_notes
        }
        c.resource_client = "rails-api"
      end

      ctx = described_class.new(claims)
      expect(ctx.has_permission?(:manage_all)).to be true      # from realm role :admin
      expect(ctx.has_permission?("write_notes")).to be true    # from resource role :editor
    ensure
      Verikloak::Pundit.configure do |c|
        c.role_map = {}
        c.resource_client = "rails-api"
        c.permission_role_scope = :default_resource
      end
    end
  end

  it "can include roles from all resource clients when opted in" do
    begin
      claims2 = {
        "realm_access" => { "roles" => [] },
        "resource_access" => {
          "rails-api" => { "roles" => [] },
          "another" => { "roles" => ["writer"] }
        }
      }
      Verikloak::Pundit.configure do |c|
        c.role_map = { writer: :write_notes }
        c.permission_role_scope = :all_resources
      end

      ctx = described_class.new(claims2)
      expect(ctx.has_permission?(:write_notes)).to be true
    ensure
      Verikloak::Pundit.configure do |c|
        c.role_map = {}
        c.permission_role_scope = :default_resource
      end
    end
  end

  it "falls back to preferred_username for email when email missing" do
    c = { "preferred_username" => "foo" }
    ctx = described_class.new(c)
    expect(ctx.email).to eq("foo")
  end

  it "in_group? behaves like has_role?" do
    c = { "realm_access" => { "roles" => ["group1"] } }
    ctx = described_class.new(c)
    expect(ctx.has_role?(:group1)).to be true
    expect(ctx.in_group?(:group1)).to be true
  end

  it "has_permission? returns false when unmapped and unmatched" do
    begin
      Verikloak::Pundit.configure { |cfg| cfg.role_map = {} }
      ctx = described_class.new(claims)
      expect(ctx.has_permission?(:something_else)).to be false
    ensure
      Verikloak::Pundit.configure { |cfg| cfg.role_map = {} }
    end
  end

  it "respects realm_roles_path customization" do
    begin
      Verikloak::Pundit.configure do |cfg|
        cfg.realm_roles_path = ["roles"]
      end
      c = { "roles" => ["alpha"] }
      ctx = described_class.new(c)
      expect(ctx.realm_roles).to eq(["alpha"])
    ensure
      Verikloak::Pundit.configure do |cfg|
        cfg.realm_roles_path = %w[realm_access roles]
      end
    end
  end

  it "uses default resource_client when none given" do
    begin
      Verikloak::Pundit.configure { |cfg| cfg.resource_client = "rails-api" }
      ctx = described_class.new(claims)
      expect(ctx.resource_roles).to include("editor")
    ensure
      Verikloak::Pundit.configure { |cfg| cfg.resource_client = "rails-api" }
    end
  end

  it "returns empty resource roles when path missing" do
    ctx = described_class.new({})
    expect(ctx.resource_roles).to eq([])
  end

  it "handles nil or non-Hash claims safely" do
    ctx = described_class.new(nil)
    expect(ctx.sub).to be_nil
    expect(ctx.email).to be_nil
    expect(ctx.realm_roles).to eq([])
    expect(ctx.resource_roles).to eq([])
    expect(ctx.has_role?(:admin)).to be false
    expect(ctx.resource_role?(:any, :role)).to be false
    expect(ctx.has_permission?(:anything)).to be false
  end

  it "supports role_map with mixed key/value types" do
    begin
      Verikloak::Pundit.configure do |c|
        c.role_map = { 'admin': 'manage_all', editor: :write_notes }
      end
      c2 = {
        'realm_access' => { 'roles' => ['admin'] },
        'resource_access' => { 'rails-api' => { 'roles' => ['editor'] } }
      }
      ctx = described_class.new(c2)
      expect(ctx.has_permission?(:manage_all)).to be true
      expect(ctx.has_permission?(:write_notes)).to be true
    ensure
      Verikloak::Pundit.configure { |c| c.role_map = {} }
    end
  end
end
