# frozen_string_literal: true

module MonitoringErrors
  module SecurityView
    module WarningsHelper
      include MonitoringErrors::SecurityView::FormattingHelper

      def summary_scan_info(scan)
        info = scan.scan_info || {}
        controllers = info['number_of_controllers'].to_i
        models = info['number_of_models'].to_i
        templates = info['number_of_templates'].to_i

        {
          'Controllers' => controllers,
          'Errors' => scan.errors_count,
          'Ignored Warnings' => scan.ignored_warnings_count,
          'Models' => models,
          'Security Warnings' => scan.warnings_count,
          'Templates' => templates
        }
      end

      def summary_warning_type(scan)
        scan.monitoring_security_warnings.group(:warning_type).order('count_all DESC').count
      end

      def warning_location(value)
        location = { 'class' => '', 'method' => '' }
        location['class'] = value['class'] if value&.key?('class')
        location['method'] = value['method'] if value&.key?('method')
        location
      end

      def grouping_warnings(values)
        buckets = { security: [], models: [], templates: [] }

        values.each do |val|
          if val['location'].nil?
            buckets[:security] << val
            next
          end

          case val['location']['type']
          when 'model' then buckets[:models] << val
          when 'template' then buckets[:templates] << val
          else buckets[:security] << val
          end
        end

        buckets.transform_values do |warns|
          warns.sort_by { |w| [norm_conf(w.confidence), w.warning_type.to_s] }
        end
      end
    end
  end
end
