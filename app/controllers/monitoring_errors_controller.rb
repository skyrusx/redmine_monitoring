require 'securerandom'

class MonitoringErrorsController < ApplicationController
  include MonitoringErrors::Rendering
  include RedmineMonitoring::Constants
  include MonitoringErrorsHelper
  attr_reader :current_tab

  accept_api_auth :index

  before_action :require_admin
  before_action :check_monitoring_enabled
  before_action :set_current_tab

  helper_method :current_tab

  def index
    @base_scope = {
      metrics: MonitoringRequest.filter(params),
      errors: MonitoringError.filter(params),
      recommendations: MonitoringRecommendation.filter(params)
    }

    case current_tab
    when 'dashboard' then render_dashboard
    when 'metrics' then render_metrics
    when 'groups' then render_groups
    when 'recommendations' then render_recommendations
    when 'alerts' then render_alerts
    when 'security' then render_security
    else render_list_with_exports
    end
  end

  def test_error
    return render_404 unless monitoring_dev_mode?

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
    return render_404 unless monitoring_dev_mode?

    # намеренно делаем N+1: для каждой задачи читаем автора
    issues = Issue.limit(10).to_a
    # доступ к ассоциации author спровоцирует N+1, если в запросе не использовать .includes(:author)
    issues.each { |issue| issue.author.name }

    redirect_to monitoring_errors_path(tab: params[:tab]), notice: I18n.t('notices.test_n_plus_one')
  end

  def test_alert
    return render_404 unless monitoring_dev_mode?

    format = safe_format(request)
    severity = MonitoringError.severity_for(nil, RuntimeError.new('test'))

    return redirect_to monitoring_errors_path unless MonitoringError.allow_severity?(severity)
    return redirect_to monitoring_errors_path unless MonitoringError.allow_format?(format)

    MonitoringErrors::Tester.call(request, severity)

    redirect_to monitoring_errors_path(tab: params[:tab]), notice: I18n.t('notices.test_alert')
  end

  def security_scan
    unless monitoring_dev_mode?
      RedmineMonitoring::OperationalLogger.once(:security_manual_scan_blocked,
                                                level: :warn,
                                                message: 'manual security scan blocked outside development mode')
      return render_404
    end

    # режим: :auto / :api / :cli
    scan_mode = (Setting.plugin_redmine_monitoring['security_scan_mode'] || 'auto').to_s.downcase.to_sym
    RedmineMonitoring::OperationalLogger.info("manual security scan started mode=#{scan_mode}")

    # опции для API Brakeman (пример: { min_confidence: 1, ignore_file: 'config/brakeman.ignore' })
    api_options = {}

    # флаги для CLI Brakeman (пример: ['-w', '1', '-i', 'config/brakeman.ignore'])
    cli_flags = []

    result = RedmineMonitoring::Security::BrakemanIngest.call!(
      prefer: scan_mode,
      options: api_options,
      extra_args: cli_flags,
      output_html: true
    )
    scan = result[:scan]
    RedmineMonitoring::OperationalLogger.info(
      "manual security scan finished mode=#{result[:mode]} warnings=#{scan&.warnings_count} errors=#{scan&.errors_count}"
    )

    redirect_to monitoring_errors_path(tab: params[:tab]), notice: I18n.t('notices.security_scan')
  end

  def security_report
    scan = MonitoringSecurityScan.find_by(id: params[:id])
    return render_404 unless scan && scan.raw_html.present?

    send_data scan.raw_html, type: 'text/html', disposition: 'inline', filename: "security-report-#{scan.id}.html"
  end

  private

  def check_monitoring_enabled
    return if Setting.plugin_redmine_monitoring['enabled']

    RedmineMonitoring::OperationalLogger.once(:monitoring_disabled,
                                              message: 'monitoring disabled by settings')
    redirect_to home_path, notice: I18n.t('notices.check_monitoring_enabled')
  end

  def per_page_param
    per_page = params[:per_page].to_i
    return per_page if per_page.positive? && per_page <= Setting.per_page_options_array.last

    Setting.per_page_options_array.first
  end

  def send_export(format, mime_type)
    send_data MonitoringErrors::Export.new(MonitoringError.filter(params)).public_send("to_#{format}"),
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
