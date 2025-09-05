# frozen_string_literal: true

module MonitoringErrors
  module HtmlHelper
    include RedmineMonitoring::Constants

    def page_title(main, current)
      [main, current].join(' » ')
    end

    def endpoint(error)
      [error.controller_name, error.action_name].join('#')
    end

    def error_class(error)
      [error.error_class, error.exception_class].uniq.join(' / ')
    end

    def location(error)
      [error.file, error.line].join(' : ')
    end

    def user_info(user)
      user&.name.presence || '-'
    end

    def label_hint(type)
      I18n.t('label_hint', type: I18n.t("label_hint_types.#{type}"))
    end

    def reco_category(value)
      I18n.t("label_reco_categories.#{value}")
    end

    def reco_kind(value)
      I18n.t("label_reco_kinds.#{value}")
    end

    def channel_status_class(value)
      CHANNEL_STATUSES[value.to_sym][:css] || 'status-unknown'
    end

    def channel_status_label(value)
      CHANNEL_STATUSES[value.to_sym][:label] || value.to_s.humanize
    end

    def severity_label(value)
      SEVERITY_DATA[value.to_sym][:label] || value.to_s.humanize
    end

    def severity_class(value)
      SEVERITY_DATA[value.to_sym][:css] || 'severity-unknown'
    end

    def monitoring_dev_mode?
      RedmineMonitoring::Env.dev_mode?
    end

    def confidence_label(value)
      WARNING_CONFIDENCE[value.to_i]
    end

    def confidence_class(value)
      case value.to_i
      when 0 then 'high'
      when 1 then 'medium'
      else 'weak'
      end
    end

    def template_label(location, render_path)
      full_template = []
      full_template << location['template']
      if render_path[0]&.key?('class') && render_path[0]&.key?('method')
        endpoint = "(#{render_path[0]['class']}##{render_path[0]['method']})"
      end
      full_template << endpoint
      full_template.compact.join(' ')
    end
  end
end
