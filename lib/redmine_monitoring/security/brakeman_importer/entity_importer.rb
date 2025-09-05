# frozen_string_literal: true

module RedmineMonitoring
  module Security
    class BrakemanImporter
      module EntityImporter
        private

        def import_warnings(scan, scan_data)
          Array(scan_data['warnings']).each do |warning_hash|
            scan.monitoring_security_warnings.create!(map_warning_attributes(warning_hash))
          end
        end

        def import_ignored_warnings(scan, scan_data)
          Array(scan_data['ignored_warnings']).each do |warning_hash|
            scan.monitoring_security_ignored_warnings.create!(
              map_warning_attributes(warning_hash).merge(note: warning_hash['note'])
            )
          end
        end

        def import_errors(scan, scan_data)
          Array(scan_data['errors']).each do |error_hash|
            scan.monitoring_security_errors.create!(
              error: error_hash['error'],
              location: error_hash['location'],
              backtrace: error_hash['backtrace'] || []
            )
          end
        end

        def import_obsolete(scan, scan_data)
          Array(scan_data['obsolete']).map(&:to_s).uniq.each do |fingerprint|
            scan.monitoring_security_obsolete.create!(fingerprint: fingerprint)
          end
        end
      end
    end
  end
end
