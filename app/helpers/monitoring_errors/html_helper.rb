# frozen_string_literal: true

module MonitoringErrors
  module HtmlHelper
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

    def dev_mode?
      settings = Setting.plugin_redmine_monitoring || {}
      value = settings['dev_mode'] || settings[:dev_mode]
      ActiveModel::Type::Boolean.new.cast(value)
    rescue StandardError
      false
    end

    def reco_category(value)
      I18n.t("label_reco_categories.#{value}")
    end

    def reco_kind(value)
      I18n.t("label_reco_kinds.#{value}")
    end
  end
end
