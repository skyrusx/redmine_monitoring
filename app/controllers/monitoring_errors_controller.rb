class MonitoringErrorsController < ApplicationController
  include RedmineMonitoring::Constants
  include MonitoringErrorsHelper
  attr_reader :current_tab

  accept_api_auth :index

  before_action :require_admin
  before_action :check_monitoring_enabled
  before_action :set_current_tab

  helper_method :current_tab

  def index
    @base_scope = MonitoringError.filter(params)

    case current_tab
    when 'dashboard' then render_dashboard
    when 'metrics' then render_metrics
    when 'groups' then render_groups
    when 'recommendations' then render_recommendations
    else render_list_with_exports
    end
  end

  def test_error
    return render_404 unless dev_mode?

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

  def test_reco
    return render_404 unless dev_mode?

    # намеренно делаем N+1: для каждой задачи читаем автора
    issues = Issue.limit(10).to_a
    issues.each do |issue|
      # доступ к ассоциации author спровоцирует N+1, если в запросе не использовать .includes(:author)
      issue.author.name
    end

    redirect_to monitoring_errors_path(tab: params[:tab]), notice: I18n.t('notices.test_n_plus_one')
  end

  private

  def render_dashboard
    @dashboard = MonitoringErrors::Dashboard.new
  end

  def render_metrics
    @metrics = MonitoringErrors::Metrics.new(per_page_param, params[:page])
  end

  def render_groups
    @groups = MonitoringErrors::Grouper.new(@base_scope, per_page_param, params[:page])
  end

  def render_recommendations
    render_404 unless dev_mode?
    @recommendations = MonitoringErrors::Recommendations.new(per_page_param, params[:page])
  end

  def render_list_with_exports
    @lister = MonitoringErrors::Lister.new(@base_scope, per_page_param, params[:page])

    respond_to do |format|
      format.html
      AVAILABLE_EXPORT_FORMATS.each do |export_format|
        format.public_send(export_format) do
          MonitoringErrors::Exporter.new(@base_scope).send(export_format, self)
        end
      end
    end
  end

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
    @current_tab = params[:tab].presence || 'dashboard'
  end
end
