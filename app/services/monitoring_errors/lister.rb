# frozen_string_literal: true

module MonitoringErrors
  class Lister
    include RedmineMonitoring::Constants

    attr_reader :records, :paginator, :count, :limit, :filters

    def initialize(base_scope, limit, page)
      @limit = limit
      @count = base_scope.count
      @paginator = Redmine::Pagination::Paginator.new(@count, @limit, page)
      @records = build_records(base_scope)
      @filters = build_filters
    end

    private

    def build_records(scope)
      scope.includes(:user)
           .order(created_at: :desc)
           .offset(@paginator.offset)
           .limit(@paginator.per_page)
    end

    def build_filters
      {
        error_classes: error_classes,
        exception_classes: exception_classes,
        controller_names: controller_names,
        action_names: action_names,
        status_codes: status_codes,
        formats: formats,
        envs: envs,
        users: users,
        severities: severities
      }
    end

    def error_classes
      MonitoringError.distinct.pluck(:error_class).compact.sort
    end

    def exception_classes
      MonitoringError.distinct.pluck(:exception_class).compact.sort
    end

    def controller_names
      MonitoringError.distinct.pluck(:controller_name).compact.sort
    end

    def action_names
      MonitoringError.distinct.pluck(:action_name).compact.sort
    end

    def status_codes
      MonitoringError.distinct.pluck(:status_code).compact.sort
    end

    def formats
      MonitoringError.distinct.pluck(:format).compact.sort
    end

    def envs
      MonitoringError.distinct.pluck(:env).compact.sort
    end

    def users
      user_ids = MonitoringError.distinct.pluck(:user_id).compact
      return [] if user_ids.empty?

      User.where(id: user_ids).order(:login).to_a
    end

    def severities
      severities = MonitoringError.distinct.pluck(:severity).compact.sort
      severities.map(&:to_sym)
                .select { |severity| SEVERITY_DATA.key?(severity) }
                .map { |severity| [SEVERITY_DATA[severity][:label], severity] }
    end
  end
end
