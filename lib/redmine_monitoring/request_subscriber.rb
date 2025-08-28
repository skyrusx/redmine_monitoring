module RedmineMonitoring
  class RequestSubscriber
    EVENT = 'process_action.action_controller'.freeze
    ASSET_PREFIXES = %w[/assets /packs /favicon.ico /robots.txt].freeze

    def self.attach!
      return if @attached
      ActiveSupport::Notifications.subscribe(EVENT) { |*args| instance.call(*args) }
      @attached = true
    end

    def self.instance
      @instance ||= new
    end

    def call(_name, start, finish, _id, payload)
      settings = plugin_settings
      return unless settings['enable_metrics'] || settings[:enable_metrics]

      # формат запроса
      fmt = MonitoringError.normalize_format(payload[:format].presence || 'html')
      return unless MonitoringError.allow_format?(fmt)

      # базовая информация
      path = safe_string(payload[:path])
      method = safe_string(payload[:method]).upcase
      return if skip_path?(path)

      # длительность/статус
      duration_ms = ((finish - start) * 1000.0).round
      status = (payload[:status] || (payload[:exception] ? 500 : nil)).to_i

      # порог: пишем все >=400; успешные — только если дольше лимита
      threshold = (settings['slow_request_threshold_ms'].to_i rescue 0)
      if status < 400 && threshold.positive? && duration_ms < threshold
        return
      end

      headers = payload[:headers].is_a?(Hash) ? payload[:headers] : {}

      # fallback: если headers пустые — достанем из Rack env
      ip_address = headers['REMOTE_ADDR'] || headers['HTTP_X_REAL_IP'] || headers['HTTP_X_FORWARDED_FOR']
      user_agent = headers['HTTP_USER_AGENT']
      referer = headers['HTTP_REFERER']
      bytes_sent = headers['Content-Length']

      if ip_address.blank? && payload[:headers].is_a?(ActionDispatch::Http::Headers)
        req = ActionDispatch::Request.new(payload[:headers].env)
        ip_address ||= req.remote_ip
        user_agent ||= req.user_agent
        referer ||= req.referer
        bytes_sent ||= req.content_length
      end

      attrs = {
        created_at: finish,
        method: method,
        path: path,
        normalized_path: MonitoringRequest.normalize_path(path, method: method),
        controller_name: safe_string(payload[:controller]),
        action_name: safe_string(payload[:action]),
        format: fmt.downcase,
        status_code: status,
        duration_ms: duration_ms,
        view_ms: payload[:view_runtime].to_i,
        db_ms: payload[:db_runtime].to_i,
        bytes_sent: bytes_sent.to_i.nonzero?,
        user_id: (User.current&.id rescue nil),
        ip_address: ip_address,
        user_agent: user_agent,
        referer: referer,
        env: Rails.env
      }

      MonitoringRequest.create(attrs)
    rescue => e
      Rails.logger.warn "[Monitoring] RequestSubscriber failed: #{e.class}: #{e.message}"
    end

    private

    def plugin_settings
      Setting.respond_to?(:plugin_redmine_monitoring) ? (Setting.plugin_redmine_monitoring || {}) : {}
    rescue
      {}
    end

    def skip_path?(path)
      return true if path.blank?
      ASSET_PREFIXES.any? { |p| path.start_with?(p) }
    end

    def safe_string(val)
      val.to_s
    rescue
      ''
    end
  end
end
