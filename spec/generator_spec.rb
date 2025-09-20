# frozen_string_literal: true
require "spec_helper"
require "fileutils"

RSpec.describe 'Verikloak::Pundit::Generators::InstallGenerator' do
  before do
    # Provide a fake Rails::Generators base with minimal API
    module Rails; end
    module Rails::Generators; end
    class Rails::Generators::Base
      class << self
        def source_root(path = nil)
          @source_root = path if path
          @source_root
        end

        def desc(_); end
        def class_option(*); end
      end

      def initialize(args = [], options = {})
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

    # Pretend rails/generators is loaded to bypass require
    $LOADED_FEATURES << 'rails/generators'
    # Load the generator file
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
end
