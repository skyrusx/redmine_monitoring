# frozen_string_literal: true

module RedmineMonitoring
  module Constants
    USEFUL_HEADERS = %w[HTTP_USER_AGENT HTTP_REFERER HTTP_ACCEPT HTTP_ACCEPT_LANGUAGE HTTP_X_REQUESTED_WITH].freeze
    DATE_COLUMNS = %w[created_at updated_at].freeze
    NOTIFY_CHANNELS = %w[email telegram].freeze
    WARNING_CONFIDENCE = %w[Высокий Средний Слабый].freeze

    DURATION_UNITS = {
      years: 365 * 24 * 3600,
      months: 30 * 24 * 3600,
      days: 24 * 3600,
      hours: 3600,
      minutes: 60,
      seconds: 1
    }.freeze
  end
end
