# frozen_string_literal: true
require "spec_helper"
require "fileutils"

RSpec.describe 'Verikloak::Pundit::Generators::InstallGenerator' do
  before do
    # Provide a fake Rails::Generators base with minimal API
    base_class = Class.new do
      class << self
        def source_root(path = nil)
          @source_root = path if path
          @source_root
        end

        def desc(_description = nil); end
        def class_option(*); end
      end

      def initialize(_args = [], options = {})
        @options = options
      end

      def options
        @options || {}
      end

      def template(src, dest)
        src_path = File.join(self.class.source_root, src)
        FileUtils.mkdir_p(File.dirname(dest))
        FileUtils.cp(src_path, dest)
      end
    end

    stub_const('Rails', Module.new)
    stub_const('Rails::Generators', Module.new)
    stub_const('Rails::Generators::Base', base_class)

    original_require = Kernel.instance_method(:require)
    allow_any_instance_of(Object).to receive(:require) do |instance, path|
      if path == 'rails/generators'
        true
      else
        original_require.bind(instance).call(path)
      end
    end

    if defined?(Verikloak::Pundit::Generators::InstallGenerator)
      Verikloak::Pundit::Generators.send(:remove_const, :InstallGenerator)
    end

    load File.expand_path('../lib/generators/verikloak/pundit/install/install_generator.rb', __dir__)
  end

  it "creates initializer and application_policy by default" do
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        gen = Verikloak::Pundit::Generators::InstallGenerator.new
        gen.create_initializer
        gen.create_application_policy

        expect(File).to exist('config/initializers/verikloak_pundit.rb')
        expect(File).to exist('app/policies/application_policy.rb')
      end
    end
  end

  it "skips application_policy when option set" do
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        gen = Verikloak::Pundit::Generators::InstallGenerator.new([], skip_policy: true)
        gen.create_initializer
        gen.create_application_policy

        expect(File).to exist('config/initializers/verikloak_pundit.rb')
        expect(File).not_to exist('app/policies/application_policy.rb')
      end
    end
  end

  it "does not overwrite existing application_policy" do
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        FileUtils.mkdir_p('app/policies')
        File.write('app/policies/application_policy.rb', 'existing policy contents')

        gen = Verikloak::Pundit::Generators::InstallGenerator.new
        gen.create_application_policy

        expect(File.read('app/policies/application_policy.rb')).to eq('existing policy contents')
      end
    end
  end

  it "creates files with expected content" do
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        gen = Verikloak::Pundit::Generators::InstallGenerator.new
        gen.create_initializer
        gen.create_application_policy

        initializer_content = File.read('config/initializers/verikloak_pundit.rb')
        policy_content = File.read('app/policies/application_policy.rb')

        expect(initializer_content).to include('Verikloak::Pundit.configure')
        expect(initializer_content).to include('resource_client')
        expect(initializer_content).to include('role_map')

        expect(policy_content).to include('class ApplicationPolicy')
        expect(policy_content).to include('def initialize(user, record)')
        expect(policy_content).to include('def index?')
      end
    end
  end

  it "creates directories when they don't exist" do
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        gen = Verikloak::Pundit::Generators::InstallGenerator.new
        gen.create_initializer
        gen.create_application_policy

        expect(Dir.exist?('config/initializers')).to be true
        expect(Dir.exist?('app/policies')).to be true
      end
    end
  end
end
