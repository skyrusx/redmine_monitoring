# frozen_string_literal: true

require 'progress_bar'

namespace :redmine_monitoring do
  desc 'Cleanup monitoring errors'
  task cleanup: :environment do
    model = MonitoringError
    days = (Setting.plugin_redmine_monitoring['retention_days'] || model.retention_days).to_i
    batch_size = 1000

    if days <= 0
      puts "[Monitoring] retention_days=#{days} → cleanup skipped"
      next
    end

    cutoff_date = Time.current - days.days
    scope = model.where(model.arel_table[:created_at].lt(cutoff_date))

    total_to_delete = scope.count
    if total_to_delete.zero?
      puts "[Monitoring] No records older than #{cutoff_date}"
      next
    end

    puts "[Monitoring] Starting retention cleanup: #{total_to_delete} records older than #{cutoff_date}"

    bar = ProgressBar.new(total_to_delete)
    total_deleted = 0

    loop do
      deleted = scope.limit(batch_size).delete_all
      total_deleted += deleted
      deleted.times { bar.increment! }

      break if deleted < batch_size
    end

    bar.finish
    puts "\n[Monitoring] Retention cleanup done: deleted #{total_deleted} records older than #{cutoff_date}"
  end
end
