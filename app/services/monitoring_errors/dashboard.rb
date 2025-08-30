# frozen_string_literal: true

module MonitoringErrors
  class Dashboard
    include RedmineMonitoring::Constants

    attr_reader :errors_by_day, :avg_duration, :top_urls, :top_users,
                :kpi_5xx, :kpi_4xx, :kpi_slow, :kpi_avg_ms

    def initialize
      load_errors_by_day
      load_avg_duration
      load_top_urls
      load_top_users
      load_kpi
    end

    private

    def load_errors_by_day
      @errors_by_day = MonitoringError.group_by_day(:created_at, last: DEFAULT_COUNT_DAYS).count
    end

    def load_avg_duration
      @avg_duration = MonitoringRequest.group_by_day(:created_at, last: DEFAULT_COUNT_DAYS).average(:duration_ms)
    end

    def load_top_urls
      @top_urls = MonitoringRequest.group(:normalized_path)
                                   .order(Arel.sql('count_all DESC'))
                                   .limit(DEFAULT_MIN_LIMIT).count
    end

    def load_top_users
      top_users = MonitoringError.group(:user_id).order(Arel.sql('count_all DESC')).limit(DEFAULT_MIN_LIMIT).count
      @top_users = top_users.transform_keys { |id| User.find_by(id: id)&.name }
    end

    def load_kpi
      scope = MonitoringRequest.where('created_at >= ?', DEFAULT_COUNT_DAYS.days.ago)
      @kpi_5xx = scope.where('status_code >= 500').count
      @kpi_4xx = scope.where('status_code >= 400 AND status_code < 500').count
      duration_ms = if Setting.plugin_redmine_monitoring['slow_request_threshold_ms'].to_i.zero?
                      DEFAULT_BATCH_SIZE
                    else
                      Setting.plugin_redmine_monitoring['slow_request_threshold_ms'].to_i
                    end
      @kpi_slow = scope.where('duration_ms > ?', duration_ms).count
      @kpi_avg_ms = scope.average(:duration_ms).to_f.round(DEFAULT_ROUND)
    end
  end
end
