# frozen_string_literal: true
require 'progress_bar'

namespace :redmine_monitoring do
  desc "Backfill MonitoringError records (fingerprint, severity, format) with progress bar"
  task backfill: :environment do
    batch_size = (ENV['BATCH'] || 1000).to_i
    scope = MonitoringError.all
    scope = scope.where("id >= ?", ENV['FROM_ID'].to_i) if ENV['FROM_ID'].to_i.positive?
    scope = scope.where("id <= ?", ENV['TO_ID'].to_i) if ENV['TO_ID'].to_i.positive?

    total = scope.count
    puts "[Monitoring] Backfilling #{total} MonitoringError records (batch=#{batch_size})…"
    if total.zero?
      puts "[Monitoring] Nothing to backfill."
      next
    end

    dry_run = ENV['DRY_RUN'].to_s == '1'
    puts "[Monitoring] DRY RUN mode — no updates will be applied." if dry_run

    bar = ProgressBar.new(total)
    updated_count = 0

    scope.find_in_batches(batch_size: batch_size) do |batch|
      batch.each do |err|
        begin
          updates = {}

          if err.fingerprint.blank?
            updates[:fingerprint] = MonitoringError.compute_fingerprint(
              err.exception_class.presence || err.error_class,
              err.message,
              err.backtrace,
              err.file,
              err.line
            )
          end

          if err.severity.blank?
            has_exception = err.exception_class.present? || err.error_class.present?
            updates[:severity] = MonitoringError.severity_for(err.status_code, has_exception)
          end

          updates[:format] = 'html' if err.format.blank?

          unless updates.empty?
            updated_count += 1
            err.update_columns(updates) unless dry_run
          end
        rescue => e
          Rails.logger.warn "[Monitoring] backfill_errors: #{e.class}: #{e.message} (id=#{err.id})"
        ensure
          bar.increment!
        end
      end
    end

    puts "\n[Monitoring] Backfill finished."
    puts "[Monitoring] Updated #{updated_count} records#{" (simulated)" if dry_run}."
  end
end
