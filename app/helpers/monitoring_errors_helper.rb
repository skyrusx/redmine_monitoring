module MonitoringErrorsHelper
  def page_title(main, current)
    [main, current].join(" » ")
  end

  def endpoint(error)
    [error.controller_name, error.action_name].join("#")
  end

  def error_class(error)
    [error.error_class, error.exception_class].uniq.join(" /  ")
  end

  def location(error)
    [error.file, error.line].join(" : ")
  end

  def user_info(user)
    user&.login.presence || user.lastname || '-'
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
        link_to l(label), monitoring_path_with(extra_params), class: "mm-btn"
      end

      safe_join([content_tag(:span, l(:label_export_to), class: "mm-export-label"), safe_join(links, " | ")], " ")
    end
  end

  def with_tab(extra = {})
    merged = request.query_parameters.merge(extra)
    merged[:tab] ||= current_tab

    merged
  end

  def monitoring_path_with(extra = {})
    monitoring_errors_path(with_tab(extra))
  end

  def monitoring_tab_path(tab)
    monitoring_errors_path(tab: tab)
  end

  def monitoring_export_path(fmt)
    monitoring_path_with(format: fmt)
  end

  def label_hint(type)
    I18n.t("label_hint", type: I18n.t("label_hint_types.#{type}"))
  end

  def human_duration(group)
    from_time = Time.parse(group.first_seen_at.strftime("%Y-%m-%d %H:%M:%S"))
    to_time = Time.parse(group.last_seen_at.strftime("%Y-%m-%d %H:%M:%S"))

    seconds = (to_time - from_time).to_i
    return "нет" if seconds <= 0

    parts = {}

    parts[:years], seconds = seconds.divmod(365 * 24 * 3600)
    parts[:months], seconds = seconds.divmod(30 * 24 * 3600)
    parts[:days], seconds = seconds.divmod(24 * 3600)
    parts[:hours], seconds = seconds.divmod(3600)
    parts[:minutes], seconds = seconds.divmod(60)
    parts[:seconds] = seconds

    labels = {
      years: "год",
      months: "мес",
      days: "д",
      hours: "ч",
      minutes: "мин",
      seconds: "сек"
    }

    result = parts.reject { |_, v| v.zero? }
                  .map { |k, v| "#{v} #{labels[k]}" }
                  .join(" ")

    "[#{result}]"
  end

  def activity_status(group)
    datetime = group.last_seen_at.strftime("%Y-%m-%d %H:%M:%S")
    return "—" if datetime.blank?

    diff_hours = (Time.current - Time.parse(datetime)).to_i / 3600
    diff_hours > 23 ? { status: :not_active, info: "Не активна" } : { status: :active, info: "Активна" }
  end
end
