# frozen_string_literal: true

require 'json'
require_relative 'brakeman_importer/preparation'
require_relative 'brakeman_importer/entity_importer'
require_relative 'brakeman_importer/helpers'

module RedmineMonitoring
  module Security
    class BrakemanImporter
      include Preparation
      include EntityImporter
      include Helpers

      class << self
        def call(json:, html: nil, target_scan: nil)
          new.call(json: json, html: html, target_scan: target_scan)
        end
      end

      # Оркестрация (инстанс-метод, чтобы не раздувать class << self)
      def call(json:, html: nil, target_scan: nil)
        scan_data = json.is_a?(String) ? JSON.parse(json) : json
        scan_info = scan_data['scan_info'] || {}

        MonitoringSecurityScan.transaction do
          scan = prepare_scan(target_scan, scan_data, scan_info, html)

          import_warnings(scan, scan_data)
          import_ignored_warnings(scan, scan_data)
          import_errors(scan, scan_data)
          import_obsolete(scan, scan_data)

          scan.refresh_counts!
          scan
        end
      end
    end
  end
end
