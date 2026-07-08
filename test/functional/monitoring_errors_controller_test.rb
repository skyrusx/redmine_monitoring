# frozen_string_literal: true

require File.expand_path('../test_helper', __dir__)

if defined?(ActionController::TestCase) && Object.const_defined?('MonitoringErrorsController')
  class MonitoringErrorsControllerTest < ActionController::TestCase
    tests MonitoringErrorsController

    fixtures :users

    setup do
      @request.session[:user_id] = 1
      Setting.plugin_redmine_monitoring = monitoring_settings.merge('enabled' => '1')
    end

    test 'security report returns 404 when scan is missing' do
      get :security_report, params: { id: 999_999 }

      assert_response 404
    end

    test 'security report returns 404 when scan has no html report' do
      scan = MonitoringSecurityScan.create!(source: 'brakeman')

      get :security_report, params: { id: scan.id }

      assert_response 404
    end

    private

    def monitoring_settings
      Setting.plugin_redmine_monitoring || {}
    rescue StandardError
      {}
    end
  end
else
  class MonitoringErrorsControllerTest < ActiveSupport::TestCase
    test 'security report tests require Redmine controller test environment' do
      skip 'Redmine controller test environment is not loaded'
    end
  end
end
