# frozen_string_literal: true

redmine_test_helper = File.expand_path('../../../test/test_helper', __dir__)

if File.exist?("#{redmine_test_helper}.rb")
  require redmine_test_helper
else
  require 'minitest/autorun'
  require 'active_support'
  require 'active_support/test_case'

  warn "Redmine test helper not found at #{redmine_test_helper}. Running standalone-compatible tests only."

  class ActiveSupport::TestCase
    def self.fixtures(*); end unless respond_to?(:fixtures)
  end
end

class ActiveSupport::TestCase
  def require_redmine_application!(*constants)
    missing = constants.reject { |constant_name| constant_defined?(constant_name) }
    skip "Redmine application is not loaded: missing #{missing.join(', ')}" if missing.any?
  end

  def constant_defined?(constant_name)
    constant_name.to_s.split('::').inject(Object) do |namespace, name|
      return false unless namespace.const_defined?(name, false)

      namespace.const_get(name, false)
    end

    true
  rescue NameError
    false
  end
end
