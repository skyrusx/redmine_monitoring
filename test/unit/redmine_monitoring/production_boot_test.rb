# frozen_string_literal: true

require File.expand_path('../../test_helper', __dir__)

module RedmineMonitoring
  class ProductionBootTest < ActiveSupport::TestCase
    setup do
      require_redmine_application!('RedmineMonitoring::BulletIntegration')
    end

    test 'bullet integration stays disabled when dependency is unavailable' do
      BulletIntegration.stub(:bullet_available?, false) do
        refute BulletIntegration.enable?
      end
    end
  end
end
