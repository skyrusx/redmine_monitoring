# frozen_string_literal: true

module MonitoringRecommendationRetention
  extend ActiveSupport::Concern
  include RedmineMonitoring::Constants

  included do
    after_commit :enforce_retention, on: :create
  end

  def enforce_retention(batch_size: DEFAULT_BATCH_SIZE)
    self.class.enforce_retention(batch_size: batch_size)
  end

  class_methods do
    def retention_days
      fetch_setting('recommendations_retention_days',
                    DEFAULT_SETTINGS[:recommendations_retention_days]) { |value| value.to_i if value.to_i.positive? }
    end

    def enforce_retention(batch_size: DEFAULT_BATCH_SIZE)
      days = retention_days.to_i
      return 0 if days <= 0

      cutoff_time = Time.current - days.days
      deleted_total = 0

      loop do
        ids = where(arel_table[:created_at].lt(cutoff_time)).order(:created_at, :id).limit(batch_size).pluck(:id)
        break if ids.empty?

        deleted_total += where(id: ids).delete_all
      end

      deleted_total
    end

    private

    def fetch_setting(key, fallback)
      return fallback unless Setting.respond_to?(:plugin_redmine_monitoring)

      value = Setting.plugin_redmine_monitoring[key]
      processed = block_given? ? yield(value) : value.presence
      processed || fallback
    rescue StandardError
      fallback
    end
  end
end
