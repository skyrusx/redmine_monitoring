# frozen_string_literal: true

require_dependency 'monitoring_errors/cleanup'

namespace :redmine_monitoring do
  namespace :cleanup do
    desc 'Cleanup monitoring errors'
    task errors: :environment do
      print_cleanup_result(MonitoringErrors::Cleanup.call(target: :errors, **cleanup_options))
    end

    desc 'Cleanup monitoring request metrics'
    task metrics: :environment do
      print_cleanup_result(MonitoringErrors::Cleanup.call(target: :metrics, **cleanup_options))
    end

    desc 'Cleanup monitoring recommendations'
    task recommendations: :environment do
      print_cleanup_result(MonitoringErrors::Cleanup.call(target: :recommendations, **cleanup_options))
    end

    desc 'Cleanup monitoring security scans'
    task security: :environment do
      print_cleanup_result(MonitoringErrors::Cleanup.call(target: :security, **cleanup_options))
    end

    desc 'Cleanup all monitoring data by retention settings'
    task all: :environment do
      MonitoringErrors::Cleanup.call_all(**cleanup_options).each { |result| print_cleanup_result(result) }
    end
  end

  desc 'Cleanup monitoring errors by retention settings'
  task cleanup: 'cleanup:errors'
end

def cleanup_options
  {
    days: ENV['DAYS'],
    batch_size: ENV['BATCH'],
    dry_run: ENV['DRY_RUN']
  }
end

def print_cleanup_result(result)
  puts "[Monitoring] cleanup #{result.target}"
  puts "retention_days=#{result.retention_days}"
  puts "cutoff=#{result.cutoff || '-'}"
  puts "matched=#{result.matched}"
  puts "deleted=#{result.deleted}"
  puts "dry_run=#{result.dry_run}"
  puts "batch_size=#{result.batch_size}"
  puts "skipped=#{result.skipped}"
  puts '' if ENV['VERBOSE'].to_s == '1'
end
