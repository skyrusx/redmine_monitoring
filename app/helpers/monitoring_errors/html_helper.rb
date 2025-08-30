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
  end
end
