# frozen_string_literal: true

require File.expand_path('../test_helper', __dir__)

class MonitoringFiltersTest < ActiveSupport::TestCase
  fixtures :users

  setup do
    require_redmine_application!('MonitoringError', 'MonitoringRequest')

    MonitoringError.delete_all
    MonitoringRequest.delete_all
  end

  test 'error filters narrow records by class status and format' do
    create_error(error_class: 'RuntimeError', status_code: 500, format: 'html')
    create_error(error_class: 'ArgumentError', status_code: 404, format: 'json')

    result = MonitoringError.filter(error_class: 'RuntimeError', status_code: 500, error_format: 'html')

    assert_equal 1, result.count
    assert_equal 'RuntimeError', result.first.error_class
  end

  test 'request filters narrow records by method status and path' do
    MonitoringRequest.create!(method: 'GET', path: '/issues/1', normalized_path: '/issues/:id',
                              status_code: 200, duration_ms: 10, format: 'html')
    MonitoringRequest.create!(method: 'POST', path: '/projects', normalized_path: '/projects',
                              status_code: 500, duration_ms: 20, format: 'json')

    result = MonitoringRequest.filter(method: 'POST', status_code: 500, normalized_path: '/projects')

    assert_equal 1, result.count
    assert_equal '/projects', result.first.normalized_path
  end

  private

  def create_error(attributes)
    MonitoringError.create!({
      error_class: 'RuntimeError',
      message: 'boom',
      severity: 'error',
      format: 'html',
      status_code: 500,
      skip_notifications: true
    }.merge(attributes))
  end
end
