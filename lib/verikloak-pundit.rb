# frozen_string_literal: true

# Minimal shim to load the namespaced entrypoint.
#
# This file preserves compatibility with Bundler's default require
# (`require 'verikloak-pundit'`) by delegating to the real entrypoint
# under the namespaced path (`verikloak/pundit`).
require 'verikloak/pundit'
