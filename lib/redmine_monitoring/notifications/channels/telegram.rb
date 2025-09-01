# frozen_string_literal: true

require 'net/http'
require 'uri'

module RedmineMonitoring
  module Notifications
    module Channels
      class Telegram
        class << self
          def deliver(payload)
            token, chats = fetch_credentials
            return if token.blank? || chats.blank?

            text = build_text(payload)
            chats.each { |cid| post(token, cid, text) }
          end

          private

          def fetch_credentials
            s = Setting.plugin_redmine_monitoring || {}
            token = s['notify_telegram_bot_token'].to_s
            chats = s['notify_telegram_chat_ids'].to_s.lines(chomp: true).reject(&:blank?)
            [token, chats]
          end

          def build_text(payload)
            lines = []
            lines << payload[:headline].to_s
            lines << "Severity: #{payload[:severity]}  Status/Format: #{payload[:status]}/#{payload[:format]}"
            snippet = payload[:snippet].to_s
            lines << snippet unless snippet.empty?

            bt = Array(payload[:backtrace]).first(5)
            lines << bt.join("\n") if bt.any?

            url = payload[:url].to_s
            lines << url unless url.empty?

            lines.join("\n")
          end

          def post(token, chat_id, text)
            uri = URI("https://api.telegram.org/bot#{token}/sendMessage")
            Net::HTTP.post_form(uri, { chat_id: chat_id, text: text })
          rescue StandardError => e
            Rails.logger.error "[Monitoring][telegram] #{e.class}: #{e.message}"
          end
        end
      end
    end
  end
end
