# frozen_string_literal: true

require "spec_helper"

RSpec.describe Verikloak::Pundit::Helpers do
  let(:dummy_context_class) do
    Class.new do
      include Verikloak::Pundit::Helpers

      attr_reader :user

      def initialize(user)
        @user = user
      end
    end
  end

  let(:user) do
    double(
      has_role?: true,
      in_group?: true,
      resource_role?: false,
      has_permission?: true
    )
  end

  before do
    allow(Verikloak::Pundit::Helpers).to receive(:warn)
  end

  it "delegates helper methods to user" do
    ctx = dummy_context_class.new(user)

    expect(Verikloak::Pundit::Helpers).to have_received(:warn).with(
      '[DEPRECATED] Verikloak::Pundit::Helpers is deprecated. Include Verikloak::Pundit::Delegations directly instead. This will be removed in v1.0.0.'
    )

    expect(ctx.has_role?(:admin)).to be true
    expect(ctx.in_group?(:staff)).to be true
    expect(ctx.resource_role?(:client, :role)).to be false
    expect(ctx.has_permission?(:perm)).to be true
  end
end
