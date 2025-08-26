class MonitoringErrorsController < ApplicationController
  before_action :require_admin
  before_action :check_monitoring_enabled

  def index
    scope = MonitoringError.filter(params)

    @limit = per_page_param
    @count = scope.count
    @paginator = Redmine::Pagination::Paginator.new(@count, @limit, params[:page])
    @offset = @paginator.offset
    @errors = scope.order(created_at: :desc).offset(@offset).limit(@paginator.per_page)

    @error_classes = MonitoringError.distinct.pluck(:error_class).compact.sort
    @controller_names = MonitoringError.distinct.pluck(:controller_name).compact.sort
    @action_names = MonitoringError.distinct.pluck(:action_name).compact.sort
    @status_codes = MonitoringError.distinct.pluck(:status_code).compact.sort
    @formats = MonitoringError.distinct.pluck(:format).compact.sort
    @envs = MonitoringError.distinct.pluck(:env).compact.sort
    @users = User.where(id: MonitoringError.distinct.pluck(:user_id).compact)

    respond_to do |format|
      format.html
      format.csv { send_data MonitoringErrors::Export.new(scope).to_csv, filename: "monitoring_errors-#{Date.today}.csv" }
      format.pdf { send_data MonitoringErrors::Export.new(scope).to_pdf, filename: "monitoring_errors-#{Date.today}.pdf", type: "application/pdf" }
    end
  end

  def show
    @error = MonitoringError.find(params[:id])
  end

  def test_error
    MonitoringError.create!(
      exception_class: "TestError",
      error_class: "TestError",
      message: "Это тестовая ошибка",
      backtrace: "test_error_backtrace",
      status_code: 500,
      controller_name: "MonitoringErrorsController",
      action_name: "test_error",
      format: safe_format(request),
      file: __FILE__,
      line: __LINE__,
      user_id: User.current&.id,
      ip_address: request.remote_ip,
      user_agent: request.user_agent,
      referer: request.referer,
      params: safe_params(request.params).to_json,
      headers: filtered_headers.to_json,
      env: Rails.env,
      severity: 'fatal'
    )

    redirect_to monitoring_errors_path, notice: I18n.t("notices.test_error")
  end

  def clear
    MonitoringError.delete_all
    redirect_to monitoring_errors_path, notice: I18n.t("notices.clear")
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
    raw = request.headers.env.slice(*MonitoringError::USEFUL_HEADERS)
    raw.transform_values { |value| value.is_a?(String) ? value : value.to_s }
  end
end
