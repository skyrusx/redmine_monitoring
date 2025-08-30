# frozen_string_literal: true

module RedmineMonitoring
  module BulletIntegration
    module Notifier
      module Classifier
        module_function

        KIND_PATTERNS = {
          n_plus_one: [
            /n\+1\s+query\s+detected/i,
            /use\s+eager\s+loading\s+detected/i,
            /possible\s+n\+1/i
          ],
          unused_eager_loading: [
            /unused\s+eager\s+loading\s+detected/i,
            /avoid\s+eager\s+loading/i
          ],
          counter_cache: [
            /counter\s*cache/i
          ]
        }.freeze

        def classify(message)
          downcased = message.to_s.downcase

          kind =
            if Utils.any_match?(downcased, KIND_PATTERNS[:n_plus_one])
              'n_plus_one'
            elsif Utils.any_match?(downcased, KIND_PATTERNS[:unused_eager_loading])
              'unused_eager_loading'
            elsif Utils.any_match?(downcased, KIND_PATTERNS[:counter_cache])
              'counter_cache'
            else
              'other'
            end

          klass, assoc = extract_model_and_association(message)
          [kind, klass, assoc]
        end

        def extract_model_and_association(message)
          header = message.match(/([A-Z][A-Za-z0-9_:]+)\s*=>\s*\[\s*:?\s*([a-z0-9_]+)\s*\]/)
          return [header[1], header[2]] if header

          hint = message.match(/\.includes\(\s*\[?\s*:?\s*([a-z0-9_]+)\s*\]?\s*\)/i)
          return [nil, hint[1]] if hint

          [nil, nil]
        end
      end
    end
  end
end
