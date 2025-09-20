# frozen_string_literal: true
require "spec_helper"

RSpec.describe "verikloak-pundit shim require" do
  it "loads the namespaced entrypoint" do
    # Simulate a fresh require context by not relying on spec_helper load
    expect { require 'verikloak-pundit' }.not_to raise_error
    expect(defined?(Verikloak::Pundit)).to eq("constant")
  end
end

