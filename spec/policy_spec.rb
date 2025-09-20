# frozen_string_literal: true

require "spec_helper"

class DummyPolicy
  include Verikloak::Pundit::Policy
  attr_reader :user
  def initialize(user)
    @user = user
  end
end

RSpec.describe Verikloak::Pundit::Policy do
  let(:user) do
    double(
      has_role?: true,
      in_group?: false,
      resource_role?: true,
      has_permission?: false
    )
  end

  it "delegates helper methods to user" do
    p = DummyPolicy.new(user)
    expect(p.has_role?(:admin)).to be true
    expect(p.in_group?(:staff)).to be false
    expect(p.resource_role?(:client, :role)).to be true
    expect(p.has_permission?(:perm)).to be false
  end
end
