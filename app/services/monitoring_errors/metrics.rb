# frozen_string_literal: true

module MonitoringErrors
  class Metrics
    attr_reader :records, :paginator, :count, :limit, :offset, :filters

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
        normalized_paths: normalized_paths,
        ip_addresses: ip_addresses,
        methods: methods,
        status_codes: status_codes,
        users: users,
        controller_names: controller_names,
        action_names: action_names,
        formats: formats,
        envs: envs,
      }
    end

    def normalized_paths
      MonitoringRequest.distinct.pluck(:normalized_path).compact.sort
    end

    def ip_addresses
      MonitoringRequest.distinct.pluck(:ip_address).compact.sort
    end

    def methods
      MonitoringRequest.distinct.pluck(:method).compact.sort
    end

    def status_codes
      MonitoringRequest.distinct.pluck(:status_code).compact.sort
    end

    def users
      user_ids = MonitoringRequest.distinct.pluck(:user_id).compact
      return [] if user_ids.empty?

      User.where(id: user_ids).order(:login).to_a
    end

    def controller_names
      MonitoringRequest.distinct.pluck(:controller_name).compact.sort
    end

    def action_names
      MonitoringRequest.distinct.pluck(:action_name).compact.sort
    end

    def formats
      MonitoringRequest.distinct.pluck(:format).compact.sort
    end

    def envs
      MonitoringRequest.distinct.pluck(:env).compact.sort
    end
  end
end
