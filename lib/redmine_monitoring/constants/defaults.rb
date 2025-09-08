# frozen_string_literal: true

module RedmineMonitoring
  module Constants
    DEFAULT_SETTINGS = {
      enabled: true,
      dev_mode: false,
      max_errors: 10_000,
      retention_days: 90,
      log_levels: %w[fatal error warning],
      enabled_formats: %w[HTML JSON],
      enable_metrics: true,
      slow_request_threshold_ms: 0,
      metrics_max_records: 100_000,
      metrics_retention_days: 30,
      notify_enabled: true,
      notify_channels: %w[email telegram],
      notify_severity_min: 'error',
      notify_formats: %w[html],
      notify_email_recipients: '',
      notify_telegram_bot_token: '',
      notify_telegram_chat_ids: '',
      notify_include_backtrace_lines: 10,
      notify_grouping_window_sec: 300,
      notify_throttle_per_group_per_min: 5,
      security_enabled: true,
      security_allow_manual_scan: true,
      security_keep_html: true,
      enable_recommendations: true,
      enable_bullet_recommendations: true
    }.freeze

    DEFAULT_BATCH_SIZE = 1_000
    DEFAULT_STATUS_CODE = 500
    DEFAULT_COUNT_DAYS = 7
    DEFAULT_MIN_LIMIT = 5
    DEFAULT_ROUND = 2

    ADVISORY_LOCK_INTERVAL = 20
  end
end
