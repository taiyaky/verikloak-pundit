# frozen_string_literal: true

# Allows specs to `load` library files that `require` Rails components
# without adding Rails as a dependency. The stub is scoped to the example
# (rspec-mocks restores it automatically), unlike mutating $LOADED_FEATURES.
module RequireStub
  # Stub Kernel#require so the given feature names resolve as already loaded.
  #
  # @param features [Array<String>] feature names to fake (e.g. 'rails/railtie')
  def stub_require(*features)
    original = Kernel.instance_method(:require)
    # rubocop:disable RSpec/AnyInstance -- require must be intercepted on every receiver
    allow_any_instance_of(Object).to receive(:require) do |instance, path|
      features.include?(path) || original.bind(instance).call(path)
    end
    # rubocop:enable RSpec/AnyInstance
  end
end

RSpec.configure do |config|
  config.include RequireStub
end
