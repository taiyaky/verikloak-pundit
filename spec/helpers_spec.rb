# frozen_string_literal: true

require "spec_helper"

class DummyContext
  include Verikloak::Pundit::Helpers
  attr_reader :user
  def initialize(user)
    @user = user
  end
end

RSpec.describe Verikloak::Pundit::Helpers do
  let(:user) do
    double(
      has_role?: true,
      in_group?: true,
      resource_role?: false,
      has_permission?: true
    )
  end

  it "delegates helper methods to user" do
    ctx = DummyContext.new(user)
    expect(ctx.has_role?(:admin)).to be true
    expect(ctx.in_group?(:staff)).to be true
    expect(ctx.resource_role?(:client, :role)).to be false
    expect(ctx.has_permission?(:perm)).to be true
  end
end
