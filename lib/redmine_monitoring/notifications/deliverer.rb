# frozen_string_literal: true

module RedmineMonitoring
  module Notifications
    class Deliverer
      def initialize(alert_window, monitoring_error, settings)
        @alert_window = alert_window
        @monitoring_error = monitoring_error
        @settings = settings
      end

      def deliver!
        payload = PayloadBuilder.new(@monitoring_error).call
        channels = Array(@settings['notify_channels']).map(&:to_s)

        channels.each do |channel|
          ch_rec = @alert_window.channels.find_or_create_by(channel: channel)
          ch_rec.start!

          begin
            deliver_channel(channel, payload)
            ch_rec.succeed!
          rescue StandardError => e
            ch_rec.fail!(e.message)
            Rails.logger.error "[Monitoring][notify][#{channel}] #{e.class}: #{e.message}"
          end
        end
      end

      private

      def deliver_channel(channel, payload)
        case channel
        when 'email'
          Channels::Email.deliver(payload)
        when 'telegram'
          Channels::Telegram.deliver(payload)
        else
          raise "Unknown channel: #{channel}"
        end
      end
    end
  end
end
