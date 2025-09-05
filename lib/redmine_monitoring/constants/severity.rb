# frozen_string_literal: true

module RedmineMonitoring
  module Constants
    SEVERITIES = %w[fatal error warning info].freeze

    SEVERITY_DATA = {
      fatal: { label: 'Критическая ошибка', css: 'severity-fatal' },
      error: { label: 'Ошибка', css: 'severity-error' },
      warning: { label: 'Предупреждение', css: 'severity-warning' },
      info: { label: 'Информация', css: 'severity-info' }
    }.freeze
  end
end
