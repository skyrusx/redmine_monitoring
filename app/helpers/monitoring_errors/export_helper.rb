# frozen_string_literal: true

module MonitoringErrors
  module ExportHelper
    include RedmineMonitoring::Constants

    def monitoring_export_links
      content_tag(:div, class: 'mm-export') do
        links = EXPORT_FORMATS.map do |format, label|
          extra_params = if format == :json && Setting.rest_api_enabled?
                           { format: format, key: User.current.api_key }
                         else
                           { format: format }
                         end

          link_to l(label), monitoring_path_with(extra_params), class: 'mm-btn'
        end

        safe_join(
          [content_tag(:span, l(:label_export_to), class: 'mm-export-label'),
           safe_join(links, ' | ')],
          ' '
        )
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

    def monitoring_export_path(format)
      monitoring_path_with(format: format)
    end
  end
end
