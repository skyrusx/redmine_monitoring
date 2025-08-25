module MonitoringErrorsHelper
  def page_title(main, current)
    [main, current].join(" » ")
  end

  def endpoint(error)
    [error.controller_name, error.action_name].join("#")
  end

  def error_class(error)
    error.exception_class.presence || error.error_class
  end

  def location(error)
    [error.file, error.line].join(" : ")
  end

  def user_info(user)
    user.try(:login) || '-'
  end

  def pretty_json(raw, fallback: '-')
    return fallback if raw.blank?

    parsed = raw.is_a?(String) ? JSON.parse(raw) : raw
    JSON.pretty_generate(parsed)
  rescue JSON::ParserError, TypeError
    raw.presence || fallback
  end
end
