# frozen_string_literal: true

module RedmineMonitoring
  module BulletIntegration
    module Notifier
      module Utils
        module_function

        def normalize_message(raw_message)
          raw_message.is_a?(String) ? raw_message.to_s.strip : raw_message.inspect
        end

        def current_context
          cur = RedmineMonitoring::BulletIntegration::Current
          {
            controller_name: cur.controller_name,
            action_name: cur.action_name,
            path: cur.path.to_s,
            user_id: cur.user_id
          }
        end

        def build_fingerprint(kind:, klass:, association:, path:)
          MonitoringRecommendation.fingerprint_for(
            kind: kind,
            klass: klass,
            association: association,
            path: path,
            query: nil
          )
        end

        def any_match?(downcased_message, patterns)
          patterns.any? { |rx| rx.match?(downcased_message) }
        end

        def truncate(value, max_len)
          value.to_s.truncate(max_len, omission: '…')
        end
      end
    end
  end
end
