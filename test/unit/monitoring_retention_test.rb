# frozen_string_literal: true

require 'securerandom'
require File.expand_path('../test_helper', __dir__)

class MonitoringRetentionTest < ActiveSupport::TestCase
  setup do
    require_redmine_application!('MonitoringError', 'MonitoringRequest',
                                 'MonitoringRecommendation', 'MonitoringSecurityScan')

    MonitoringError.delete_all
    MonitoringRequest.delete_all
    MonitoringRecommendation.delete_all
    MonitoringSecurityScan.delete_all
  end

  test 'error retention removes old records' do
    old = create_error(created_at: 3.days.ago, updated_at: 3.days.ago)
    fresh = create_error(created_at: Time.current, updated_at: Time.current)

    MonitoringError.stub(:retention_days, 1) { fresh.enforce_retention(batch_size: 100) }

    assert_nil MonitoringError.find_by(id: old.id)
    assert MonitoringError.exists?(fresh.id)
  end

  test 'error max records keeps latest records' do
    first = create_error(created_at: 3.days.ago, updated_at: 3.days.ago)
    second = create_error(created_at: 2.days.ago, updated_at: 2.days.ago)
    third = create_error(created_at: 1.day.ago, updated_at: 1.day.ago)

    MonitoringError.stub(:max_errors, 2) { third.enforce_max_errors }

    refute MonitoringError.exists?(first.id)
    assert MonitoringError.exists?(second.id)
    assert MonitoringError.exists?(third.id)
  end

  test 'request maintenance enforces retention and max records' do
    old = create_request(created_at: 3.days.ago, updated_at: 3.days.ago)
    fresh = create_request(created_at: Time.current, updated_at: Time.current)

    MonitoringRequest.stub(:retention_days, 1) do
      MonitoringRequest.stub(:max_records, 1) do
        MonitoringRequest.maintain!
      end
    end

    refute MonitoringRequest.exists?(old.id)
    assert MonitoringRequest.exists?(fresh.id)
  end

  test 'recommendation retention removes old records' do
    old = create_recommendation(created_at: 3.days.ago, updated_at: 3.days.ago)
    fresh = create_recommendation(created_at: Time.current, updated_at: Time.current)

    MonitoringRecommendation.stub(:retention_days, 1) do
      MonitoringRecommendation.enforce_retention
    end

    refute MonitoringRecommendation.exists?(old.id)
    assert MonitoringRecommendation.exists?(fresh.id)
  end

  test 'security scan retention removes old records' do
    old = create_security_scan(created_at: 3.days.ago, updated_at: 3.days.ago)
    fresh = create_security_scan(created_at: Time.current, updated_at: Time.current)

    MonitoringSecurityScan.stub(:retention_days, 1) do
      MonitoringSecurityScan.enforce_retention
    end

    refute MonitoringSecurityScan.exists?(old.id)
    assert MonitoringSecurityScan.exists?(fresh.id)
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
