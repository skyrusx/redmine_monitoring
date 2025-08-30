# frozen_string_literal: true

module RedmineMonitoring
  module BulletIntegration
    # IO-адаптер: uniform_notifier пишет сюда, а мы — в Notifier.ingest
    class IoAdapter
      attr_reader :sync

      def write(raw)
        Notifier.ingest(raw)
      end

      def <<(raw)
        Notifier.ingest(raw)
      end

      def close
        true
      end

      def sync=(val)
        @sync = !!val
      end

      def tty?
        false
      end
    end
  end
end
