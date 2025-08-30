# frozen_string_literal: true

module RedmineMonitoring
  class ErrorReporter
    include Constants

    def initialize(logger:)
      @logger = logger
    end

    # совместимо с Ruby 2.6 — без шортхенда request:
    def save(env:, exception: nil, status: nil, severity: 'fatal')
      return unless MonitoringError.allow_severity?(severity)

      request = ActionDispatch::Request.new(env)
      return unless MonitoringError.allow_format?(safe_format(request))

      attributes = build_attributes(
        request: request,
        controller_instance: env['action_controller.instance'],
        exception: exception,
        status: status,
        severity: severity
      )

      MonitoringError.create!(attributes)
    rescue StandardError => e
      @logger.error "[Monitoring] Ошибка при сохранении HTTP #{status}: #{e.class} #{e.message}"
    end

    private

    def build_attributes(request:, controller_instance:, exception:, status:, severity:)
      RedmineMonitoring::ErrorAttributesBuilder.new(
        request: request,
        controller_instance: controller_instance,
        exception: exception,
        status: status,
        severity: severity
      ).build
    end

    # минимальные локальные утилиты (чтобы не тянуть middleware)
    def safe_format(request)
      (request.format&.symbol || :html).to_s
    rescue StandardError
      'html'
    end
  end
end
