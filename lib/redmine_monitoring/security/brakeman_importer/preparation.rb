# frozen_string_literal: true

module RedmineMonitoring
  module Security
    class BrakemanImporter
      module Preparation
        private

        def prepare_scan(target_scan, scan_data, scan_info, html)
          scan = target_scan || MonitoringSecurityScan.new
          attributes = build_scan_attributes(scan, scan_data, scan_info, html)

          if scan.persisted?
            scan.update!(attributes)
            reset_scan_results(scan)
          else
            scan.assign_attributes(attributes)
            scan.save!
          end

          scan
        end

        def build_scan_attributes(scan, scan_data, scan_info, html)
          {
            source: 'brakeman',
            app_path: scan_info['app_path'],
            rails_version: scan_info['rails_version'],
            ruby_version: scan_info['ruby_version'],
            scanner_version: scan_info['brakeman_version'],
            started_at: safe_time(scan_info['start_time']) || scan.started_at,
            ended_at: safe_time(scan_info['end_time']) || scan.ended_at,
            duration: extract_duration(scan_info, scan_data),
            checks_performed: extract_checks_performed(scan_info, scan_data),
            scan_info: scan_info,
            raw_json: scan_data,
            raw_html: html
          }
        end

        def extract_duration(scan_info, scan_data)
          (scan_info['duration'] || scan_data['duration']).to_f
        end

        def extract_checks_performed(scan_info, scan_data)
          scan_info['checks_performed'] || scan_data['checks_performed'] || []
        end

        def reset_scan_results(scan)
          scan.monitoring_security_warnings.delete_all
          scan.monitoring_security_ignored_warnings.delete_all
          scan.monitoring_security_errors.delete_all
          scan.monitoring_security_obsolete.delete_all
        end
      end
    end
  end
end
