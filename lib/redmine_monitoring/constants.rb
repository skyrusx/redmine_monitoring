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
      slow_request_threshold_ms: 0
    }.freeze

    DEFAULT_BATCH_SIZE = 1_000
    DEFAULT_STATUS_CODE = 500
    DEFAULT_COUNT_DAYS = 7
    DEFAULT_MIN_LIMIT = 5
    DEFAULT_ROUND = 2

    ADVISORY_LOCK_INTERVAL = 20

    SEVERITIES = %w[fatal error warning info].freeze
    ENABLED_FORMATS = %w[HTML JSON CSV PDF XLSX XML].freeze
    USEFUL_HEADERS = %w[HTTP_USER_AGENT HTTP_REFERER HTTP_ACCEPT HTTP_ACCEPT_LANGUAGE HTTP_X_REQUESTED_WITH].freeze
    DATE_COLUMNS = %w[created_at updated_at].freeze

    MIME_TYPES = {
      csv: 'text/csv',
      json: 'application/json',
      pdf: 'application/pdf',
      xlsx: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
    }.freeze

    EXPORT_FORMATS = {
      csv: :label_export_csv,
      xlsx: :label_export_xlsx,
      json: :label_export_json,
      pdf: :label_export_pdf
    }.freeze

    DURATION_UNITS = {
      years: 365 * 24 * 3600,
      months: 30 * 24 * 3600,
      days: 24 * 3600,
      hours: 3600,
      minutes: 60,
      seconds: 1
    }.freeze

    HTTP_STATUS_TEXT = {
      100 => 'Continue',
      101 => 'Switching Protocols',
      102 => 'Processing',
      103 => 'Early Hints',

      200 => 'OK',
      201 => 'Created',
      202 => 'Accepted',
      203 => 'Non-Authoritative Information',
      204 => 'No Content',
      205 => 'Reset Content',
      206 => 'Partial Content',
      207 => 'Multi-Status',
      208 => 'Already Reported',
      226 => 'IM Used',

      300 => 'Multiple Choices',
      301 => 'Moved Permanently',
      302 => 'Found',
      303 => 'See Other',
      304 => 'Not Modified',
      305 => 'Use Proxy',
      307 => 'Temporary Redirect',
      308 => 'Permanent Redirect',

      400 => 'Bad Request',
      401 => 'Unauthorized',
      403 => 'Forbidden',
      404 => 'Not Found',
      405 => 'Method Not Allowed',
      408 => 'Request Timeout',
      422 => 'Unprocessable Entity',
      429 => 'Too Many Requests',

      500 => 'Internal Server Error',
      502 => 'Bad Gateway',
      503 => 'Service Unavailable',
      504 => 'Gateway Timeout'
    }.freeze
  end
end
