# frozen_string_literal: true

require 'securerandom'
require File.expand_path('../test_helper', __dir__)

class MonitoringCleanupTest < ActiveSupport::TestCase
  setup do
    require_redmine_application!('MonitoringErrors::Cleanup', 'MonitoringError', 'MonitoringRequest',
                                 'MonitoringRecommendation', 'MonitoringSecurityScan')

    MonitoringError.delete_all
    MonitoringRequest.delete_all
    MonitoringRecommendation.delete_all
    MonitoringSecurityScan.delete_all
  end

  test 'dry run counts old records without deleting them' do
    old = create_error(created_at: 10.days.ago, updated_at: 10.days.ago)

    result = MonitoringErrors::Cleanup.call(target: :errors, days: 1, dry_run: true)

    assert_equal :errors, result.target
    assert_equal 1, result.matched
    assert_equal 0, result.deleted
    assert MonitoringError.exists?(old.id)
  end

  test 'cleanup deletes old records by explicit days override' do
    old = create_error(created_at: 10.days.ago, updated_at: 10.days.ago)
    fresh = create_error(created_at: Time.current, updated_at: Time.current)

    result = MonitoringErrors::Cleanup.call(target: :errors, days: 1, batch_size: 1)

    assert_equal 1, result.matched
    assert_equal 1, result.deleted
    refute MonitoringError.exists?(old.id)
    assert MonitoringError.exists?(fresh.id)
  end

  test 'cleanup all executes every target' do
    create_error(created_at: 10.days.ago, updated_at: 10.days.ago)
    create_request(created_at: 10.days.ago, updated_at: 10.days.ago)
    create_recommendation(created_at: 10.days.ago, updated_at: 10.days.ago)
    create_security_scan(created_at: 10.days.ago, updated_at: 10.days.ago)

    results = MonitoringErrors::Cleanup.call_all(days: 1)

    assert_equal %i[errors metrics recommendations security], results.map(&:target)
    assert results.all? { |result| result.deleted == 1 }
  end

  test 'unknown target raises a clear error' do
    error = assert_raises(ArgumentError) do
      MonitoringErrors::Cleanup.call(target: :unknown)
    end

    assert_includes error.message, 'Unknown cleanup target'
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

  def create_request(attributes)
    MonitoringRequest.create!({
      method: 'GET',
      path: '/issues/1',
      normalized_path: '/issues/:id',
      status_code: 200,
      duration_ms: 10,
      format: 'html'
    }.merge(attributes))
  end

  def create_recommendation(attributes)
    MonitoringRecommendation.create!({
      source: 'bullet',
      category: 'performance',
      kind: 'n_plus_one_query',
      message: 'Use includes',
      fingerprint: SecureRandom.hex(20)
    }.merge(attributes))
  end

  def create_security_scan(attributes)
    MonitoringSecurityScan.create!({
      source: 'brakeman'
    }.merge(attributes))
  end
end
