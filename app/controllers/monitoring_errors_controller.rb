class MonitoringErrorsController < ApplicationController
  include RedmineMonitoring::Constants
  attr_reader :current_tab

  accept_api_auth :index

  before_action :require_admin
  before_action :check_monitoring_enabled
  before_action :set_current_tab

  helper_method :current_tab

  def index
    @current_tab = params[:tab].presence || 'dashboard'
    @base_scope = MonitoringError.filter(params)

    case @current_tab
    when 'dashboard'
      @dashboard = MonitoringErrors::Dashboard.new
    when 'metrics'
      @metrics = MonitoringErrors::Metrics.new(per_page_param, params[:page])
    when 'groups'
      @groups = MonitoringErrors::Grouper.new(@base_scope, per_page_param, params[:page])
    else
      @lister = MonitoringErrors::Lister.new(@base_scope, per_page_param, params[:page])
      respond_to do |format|
        format.html
        %i[csv json pdf xlsx].each do |export_format|
          format.public_send(export_format) do
            MonitoringErrors::Exporter.new(@base_scope).send(export_format, self)
          end
        end
      end
    end
  end

  def test_error
    format = safe_format(request)
    severity = MonitoringError.severity_for(nil, RuntimeError.new('test'))

    return redirect_to monitoring_errors_path unless MonitoringError.allow_severity?(severity)
    return redirect_to monitoring_errors_path unless MonitoringError.allow_format?(format)

    MonitoringErrors::Tester.call(request, severity)

    redirect_to monitoring_errors_path(tab: params[:tab]), notice: I18n.t('notices.test_error')
  end

  def clear
    MonitoringErrors::Cleaner.call(params[:tab])
    redirect_to monitoring_errors_path(tab: params[:tab]), notice: I18n.t("notices.clear.#{params[:tab]}")
  end

  private

  def check_monitoring_enabled
    return if Setting.plugin_redmine_monitoring['enabled']

    redirect_to home_path, notice: I18n.t('notices.check_monitoring_enabled')
  end

  def per_page_param
    per_page = params[:per_page].to_i
    return per_page if per_page.positive? && per_page <= Setting.per_page_options_array.last

    Setting.per_page_options_array.first
  end

  def send_export(format, mime_type)
    send_data MonitoringErrors::Export.new(@base_scope).public_send("to_#{format}"),
              filename: "monitoring-errors__#{Time.zone.today}.#{format}",
              type: mime_type
  end

  def safe_format(request)
    (request.format&.symbol || :html).to_s
  rescue StandardError
    'html'
  end

  def set_current_tab
    @current_tab = params[:tab].presence || 'errors'
  end
end
