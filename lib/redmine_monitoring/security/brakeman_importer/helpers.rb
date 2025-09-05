# frozen_string_literal: true

module RedmineMonitoring
  module Security
    class BrakemanImporter
      module Helpers
        private

        def safe_time(time_string)
          return nil if time_string.to_s.strip.empty?

          Time.zone.parse(time_string.to_s)
        rescue StandardError
          nil
        end

        def confidence_level(confidence_value)
          normalized = confidence_value.to_s.downcase
          return 0 if %w[high 0].include?(normalized)
          return 1 if %w[medium 1].include?(normalized)
          return 2 if %w[weak low 2].include?(normalized)

          2
        end

        def map_warning_attributes(warning_hash)
          raw_warning_id = warning_hash['warning_id'] || warning_hash['id']
          warning_id = raw_warning_id.to_s.strip.empty? ? nil : raw_warning_id.to_i

          {
            warning_id: warning_id,
            warning_type: warning_hash['warning_type'],
            warning_code: warning_hash['warning_code'],
            fingerprint: warning_hash['fingerprint'].to_s, # допускаем повторы
            check_name: warning_hash['check_name'],
            message: warning_hash['message'],
            file: warning_hash['file'],
            line: warning_hash['line'],
            link: warning_hash['link'],
            code: warning_hash['code'],
            render_path: (warning_hash['render_path'] || []),
            location: warning_hash['location'],
            user_input: warning_hash['user_input'],
            confidence: confidence_level(warning_hash['confidence']),
            cwe_ids: (warning_hash['cwe_id'] || warning_hash['cwe_ids'] || [])
          }
        end

        def dedupe_by_fingerprint(items)
          seen_fingerprints = {}
          Array(items).compact.each_with_object([]) do |item, unique_items|
            fingerprint = item['fingerprint'].to_s
            next if fingerprint.empty? || seen_fingerprints[fingerprint]

            seen_fingerprints[fingerprint] = true
            unique_items << item
          end
        end
      end
    end
  end
end
