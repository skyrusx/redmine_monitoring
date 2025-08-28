class MonitoringErrorsController < ApplicationController
  include RedmineMonitoring::Constants

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
      @errors_by_day = MonitoringError.group_by_day(:created_at, last: 7).count
      @avg_duration = MonitoringRequest.group_by_day(:created_at, last: 7).average(:duration_ms)

      @top_urls = MonitoringRequest.group(:normalized_path).order(Arel.sql("count_all DESC")).limit(5).count
      top_users = MonitoringError.group(:user_id).order(Arel.sql("count_all DESC")).limit(5).count
      @top_users = top_users.transform_keys { |user_id| User.find_by(id: user_id)&.name }

      @kpi_5xx = MonitoringRequest.where("status_code >= 500").where("created_at >= ?", 7.days.ago).count
      @kpi_4xx = MonitoringRequest.where("status_code >= 400 AND status_code < 500").where("created_at >= ?", 7.days.ago).count
      @kpi_slow = MonitoringRequest.where("duration_ms > ?", 1000).where("created_at >= ?", 7.days.ago).count
      @kpi_avg_ms = MonitoringRequest.where("created_at >= ?", 7.days.ago).average(:duration_ms).to_f.round(2)
    when 'metrics'
      metrics_scope = MonitoringRequest.all.order(created_at: :desc)

      @limit = per_page_param
      @count = metrics_scope.count
      @paginator = Redmine::Pagination::Paginator.new(@count, @limit, params[:page])
      @offset = @paginator.offset

      @metrics = metrics_scope.order(created_at: :desc).offset(@offset).limit(@paginator.per_page)
    when 'groups'
      adapter = ActiveRecord::Base.connection.adapter_name.downcase
      first_frame_sql = adapter.include?('postgres') ? "substring(backtrace from '^[^\\n]+')" : "SUBSTRING_INDEX(backtrace, '\n', 1)"

      groups_scope = @base_scope.select("exception_class, message, #{first_frame_sql} AS first_frame,
                                        COUNT(*) AS count,
                                        MIN(created_at) AS first_seen_at,
                                        MAX(created_at) AS last_seen_at, MIN(error_class) AS error_class")
                                .group("exception_class, message, #{first_frame_sql}")

      @count = groups_scope.except(:select, :order).count.size
      @limit = per_page_param
      @paginator = Redmine::Pagination::Paginator.new(@count, @limit, params[:page])

      @groups = groups_scope.order("count DESC, last_seen_at DESC").offset(@paginator.offset).limit(@paginator.per_page)
    else
      @limit = per_page_param
      @count = @base_scope.count
      @paginator = Redmine::Pagination::Paginator.new(@count, @limit, params[:page])
      @offset = @paginator.offset
      @errors = @base_scope.order(created_at: :desc).offset(@offset).limit(@paginator.per_page)

      @error_classes = MonitoringError.distinct.pluck(:error_class).compact.sort
      @exception_classes = MonitoringError.distinct.pluck(:exception_class  ).compact.sort
      @controller_names = MonitoringError.distinct.pluck(:controller_name).compact.sort
      @action_names = MonitoringError.distinct.pluck(:action_name).compact.sort
      @status_codes = MonitoringError.distinct.pluck(:status_code).compact.sort
      @formats = MonitoringError.distinct.pluck(:format).compact.sort
      @envs = MonitoringError.distinct.pluck(:env).compact.sort
      @users = User.where(id: MonitoringError.distinct.pluck(:user_id).compact)
      @severities = MonitoringError.distinct.pluck(:severity).compact.sort

      respond_to do |format|
        format.html
        format.csv { send_data MonitoringErrors::Export.new(@base_scope).to_csv, filename: "monitoring_errors-#{Date.today}.csv" }
        format.json { send_data MonitoringErrors::Export.new(@base_scope).to_json, filename: "monitoring_errors-#{Date.today}.json", type: "application/json" }
        format.pdf { send_data MonitoringErrors::Export.new(@base_scope).to_pdf, filename: "monitoring_errors-#{Date.today}.pdf", type: "application/pdf" }
        format.xlsx { send_data MonitoringErrors::Export.new(@base_scope).to_xlsx, filename: "monitoring_errors-#{Date.today}.xlsx" }
      end
    end
  end

  def show
    @error = MonitoringError.find(params[:id])
  end

  def test_error
    format = safe_format(request)
    severity = MonitoringError.severity_for(nil, RuntimeError.new("test"))

    return redirect_to monitoring_errors_path unless MonitoringError.allow_severity?(severity)
    return redirect_to monitoring_errors_path unless MonitoringError.allow_format?(format)

    MonitoringError.create!(
      exception_class: "TestError",
      error_class: "TestError",
      message: "Это тестовая ошибка",
      backtrace: "test_error_backtrace",
      status_code: 500,
      controller_name: "MonitoringErrorsController",
      action_name: "test_error",
      format: format,
      file: __FILE__,
      line: __LINE__,
      user_id: User.current&.id,
      ip_address: request.remote_ip,
      user_agent: request.user_agent,
      referer: request.referer,
      params: safe_params(request.params).to_json,
      headers: filtered_headers.to_json,
      env: Rails.env,
      severity: severity
    )

    redirect_to monitoring_errors_path(tab: params[:tab]), notice: I18n.t("notices.test_error")
  end

  def clear
    case params[:tab]
    when "errors" then MonitoringError.in_batches(of: 1000).delete_all
    when "metrics" then MonitoringRequest.in_batches(of: 1000).delete_all
    else nil
    end
    redirect_to monitoring_errors_path(tab: params[:tab]), notice: I18n.t("notices.clear.#{params[:tab]}")
  end

  private

  def check_monitoring_enabled
    unless Setting.plugin_redmine_monitoring['enabled']
      redirect_to '/', notice: I18n.t("notices.check_monitoring_enabled")
    end
  end

  def per_page_param
    per_page = params[:per_page].to_i
    return per_page if per_page.positive? && per_page <= Setting.per_page_options_array.last
    Setting.per_page_options_array.first
  end

  def safe_format(request)
    (request.format&.symbol || :html).to_s
  rescue
    'html'
  end

  def safe_params(params)
    return {} unless params
    hash = params.respond_to?(:to_unsafe_h) ? params.to_unsafe_h : params.to_h
    hash.except(:controller, :action)
  rescue
    {}
  end

  def filtered_headers
    raw = request.headers.env.slice(*USEFUL_HEADERS)
    raw.transform_values { |value| value.is_a?(String) ? value : value.to_s }
  end

  def set_current_tab
    @current_tab = params[:tab].presence || 'errors'
  end

  def current_tab
    @current_tab
  end
end
