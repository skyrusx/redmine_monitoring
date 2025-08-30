# frozen_string_literal: true

module RedmineMonitoring
  module BulletIntegration
    module Notifier
      module Parser
        module_function

        SUGGESTION_PATTERNS = {
          add_includes: /add to your query:\s*\.includes\(\s*\[?(.+?)\]?\s*\)/i,
          remove_includes: /remove from your query:\s*\.includes\(\s*\[?(.+?)\]?\s*\)/i
        }.freeze

        def build_details(message)
          text = message.to_s
          lines = text.split("\n")
          split_index = lines.index { |line| line.to_s.downcase.include?('call stack') } || lines.length

          action, include_list = extract_suggestion(text)

          payload = {
            header: lines[0, split_index].join("\n"),
            callstack: lines[(split_index + 1)..]&.join("\n"),
            action: action,
            includes: include_list
          }
          payload.delete_if { |_k, v| v.nil? || (v.respond_to?(:empty?) && v.empty?) }
        end

        def extract_suggestion(text)
          SUGGESTION_PATTERNS.each do |action_key, regexp|
            match = text.match(regexp)
            next unless match

            return [action_key.to_s, normalize_includes_list(match[1])]
          end
          [nil, nil]
        end

        def normalize_includes_list(raw_inside)
          return nil if raw_inside.nil?

          inside = raw_inside.to_s.strip
          inside = inside[1..-2] if inside.start_with?('[') && inside.end_with?(']')
          inside.split(',').map { |token| token.to_s.strip.delete_prefix(':') }.reject(&:empty?)
        end
      end
    end
  end
end
