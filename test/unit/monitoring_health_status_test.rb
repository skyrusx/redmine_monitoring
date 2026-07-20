# frozen_string_literal: true

require 'securerandom'
require File.expand_path('../test_helper', __dir__)

class MonitoringHealthStatusTest < ActiveSupport::TestCase
  setup do
    require_redmine_application!('MonitoringErrors::HealthStatus', 'MonitoringError', 'MonitoringRequest',
                                 'MonitoringRecommendation', 'MonitoringAlert', 'MonitoringAlertChannel',
                                 'MonitoringSecurityScan', 'Setting')

    MonitoringAlertChannel.delete_all
    MonitoringAlert.delete_all
    MonitoringError.delete_all
    MonitoringRequest.delete_all
    MonitoringRecommendation.delete_all
    MonitoringSecurityScan.delete_all

    Setting.plugin_redmine_monitoring = {
      'enabled' => '1',
      'enable_metrics' => '1',
      'enable_recommendations' => '1',
      'notify_enabled' => '1',
      'notify_channels' => %w[email telegram],
      'notify_email_recipients' => 'admin@example.test',
      'notify_telegram_bot_token' => 'token',
      'notify_telegram_chat_ids' => "100\n200",
      'security_enabled' => '1'
    }
  end

  test 'health status exposes counts settings and notification diagnostics' do
    create_error
    create_request
    create_recommendation
    create_alert_channel
    MonitoringSecurityScan.create!(source: 'brakeman')

    health = MonitoringErrors::HealthStatus.new

    assert health.settings_status[:monitoring_enabled]
    assert health.settings_status[:metrics_enabled]
    assert_equal 1, health.counts[:errors]
    assert_equal 1, health.counts[:metrics]
    assert_equal 1, health.counts[:recommendations]
    assert_equal 1, health.counts[:alerts]
    assert_equal 1, health.counts[:security_scans]
    assert health.notifications[:email_configured]
    assert health.notifications[:telegram_configured]
    assert_equal 'failed', health.notifications[:last_status]
    assert_equal 'timeout', health.notifications[:last_error]
  end

  private

  def create_error
    MonitoringError.create!(
      error_class: 'RuntimeError',
      message: 'boom',
      severity: 'error',
      format: 'html',
      status_code: 500,
      skip_notifications: true
    )
  end

  def create_request
    MonitoringRequest.create!(
      method: 'GET',
      path: '/issues/1',
      normalized_path: '/issues/:id',
      status_code: 200,
      duration_ms: 10,
      format: 'html'
    )
  end

  def create_recommendation
    MonitoringRecommendation.create!(
      source: 'bullet',
      category: 'performance',
      kind: 'n_plus_one_query',
      message: 'Use includes',
      fingerprint: SecureRandom.hex(20)
    )
  end

  def create_alert_channel
    alert = MonitoringAlert.create!(
      fingerprint: SecureRandom.hex(20),
      first_error_id: 1,
      last_error_id: 1,
      first_seen_at: Time.current,
      last_seen_at: Time.current,
      window_started_at: Time.current
    )

    MonitoringAlertChannel.create!(
      monitoring_alert: alert,
      channel: 'email',
      status: 'failed',
      last_error: 'timeout',
      last_sent_at: Time.current
    )
  end
end
