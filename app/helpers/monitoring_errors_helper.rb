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

  def monitoring_export_links
    formats = { csv: :label_export_csv, xlsx: :label_export_xlsx, json: :label_export_json, pdf: :label_export_pdf }

    content_tag(:div, class: "mm-export") do
      links = formats.map do |format, label|
        extra_params = format == :json && Setting.rest_api_enabled? ? { format: format, key: User.current.api_key } : { format: format }
        link_to l(label), monitoring_errors_path(extra_params), class: "mm-btn"
      end

      safe_join([content_tag(:span, l(:label_export_to), class: "mm-export-label"), safe_join(links, " | ")], " ")
    end
  end
end
