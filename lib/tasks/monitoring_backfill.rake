# frozen_string_literal: true

require 'progress_bar'

namespace :redmine_monitoring do
  desc 'Backfill MonitoringError records (fingerprint, severity, format) with progress bar'
  task backfill: :environment do
    MonitoringBackfill.call
  end
end

module MonitoringBackfill
  module_function

  def call
    scope = build_scope
    batch_size = env_int('BATCH', 1000)
    dry_run = ENV['DRY_RUN'].to_s == '1'

    total = scope.count
    puts "[Monitoring] Backfilling #{total} MonitoringError records (batch=#{batch_size})…"
    return puts('[Monitoring] Nothing to backfill.') if total.zero?

    puts '[Monitoring] DRY RUN mode — no updates will be applied.' if dry_run

    bar = ProgressBar.new(total)
    updated_count = 0

    scope.find_in_batches(batch_size: batch_size) do |batch|
      batch.each do |err|
        updated_count += 1 if process_record(err, dry_run)
      rescue StandardError => e
        Rails.logger.warn "[Monitoring] backfill_errors: #{e.class}: #{e.message} (id=#{err.id})"
      ensure
        bar.increment!
      end
    end

    puts "\n[Monitoring] Backfill finished."
    puts "[Monitoring] Updated #{updated_count} records#{' (simulated)' if dry_run}."
  end

  def build_scope
    scope = MonitoringError.all
    from_id = env_int('FROM_ID', 0)
    to_id = env_int('TO_ID', 0)

    scope = scope.where('id >= ?', from_id) if from_id.positive?
    scope = scope.where('id <= ?', to_id) if to_id.positive?
    scope
  end

  def process_record(err, dry_run)
    updates = {}
    updates[:fingerprint] = build_fingerprint(err) if err.fingerprint.blank?
    updates[:severity]    = build_severity(err)    if err.severity.blank?
    updates[:format]      = 'html'                 if err.format.blank?

    return false if updates.empty?

    err.update_columns(updates) unless dry_run
    true
  end

  def build_fingerprint(err)
    MonitoringError.compute_fingerprint(
      err.exception_class.presence || err.error_class,
      err.message,
      err.backtrace,
      err.file,
      err.line
    )
  end

  def build_severity(err)
    has_exception = err.exception_class.present? || err.error_class.present?
    MonitoringError.severity_for(err.status_code, has_exception)
  end

  def env_int(key, default)
    (ENV[key] || default).to_i
  end
end
