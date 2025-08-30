# frozen_string_literal: true

require_relative 'notifier/classifier'
require_relative 'notifier/parser'
require_relative 'notifier/utils'

module RedmineMonitoring
  module BulletIntegration
    module Notifier
      module_function

      def ingest(raw_message)
        message = Utils.normalize_message(raw_message)
        return if message.empty?

        kind, model_class, association = Classifier.classify(message)
        details_payload = Parser.build_details(message)

        attrs = {
          kind: kind,
          message: message,
          details: details_payload,
          model_class: model_class,
          association: association,
          context: Utils.current_context
        }

        create_recommendation(attrs)
      rescue StandardError => e
        Rails.logger.warn "[Monitoring/Bullet] ingest failed: #{e.class}: #{e.message}"
      end

      def create_recommendation(attrs)
        ctx = attrs[:context]

        MonitoringRecommendation.create!(
          source: 'bullet',
          category: 'performance',
          kind: attrs[:kind],
          message: Utils.truncate(attrs[:message], 10_000),
          details: attrs[:details],
          controller_name: ctx[:controller_name],
          action_name: ctx[:action_name],
          path: ctx[:path],
          user_id: ctx[:user_id],
          fingerprint: Utils.build_fingerprint(
            kind: attrs[:kind],
            klass: attrs[:model_class],
            association: attrs[:association],
            path: ctx[:path]
          )
        )
      end
    end
  end
end
