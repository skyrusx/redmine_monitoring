# frozen_string_literal: true

require File.expand_path('../../test_helper', __dir__)

module RedmineMonitoring
  class BulletIntegrationTest < ActiveSupport::TestCase
    test 'bullet availability check does not raise when dependency is optional' do
      assert_includes [true, false], BulletIntegration.send(:bullet_available?)
    end
  end
end
