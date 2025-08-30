# frozen_string_literal: true

module MonitoringErrorFingerprint
  extend ActiveSupport::Concern

  def assign_fingerprint
    self.fingerprint ||= self.class.compute_fingerprint(exception_class || error_class, message, backtrace, file, line)
  end

  class_methods do
    def compute_fingerprint(exception_class, message, backtrace, source_file = nil, source_line = nil)
      normalized_message = message.to_s.gsub(/\d+/, ':n').gsub(/[0-9a-f]{8,}/i, ':h').strip.downcase

      first_frame = if backtrace.present?
                      frame = backtrace.is_a?(Array) ? backtrace.first.to_s : backtrace.to_s.lines.first.to_s
                      frame.strip
                    else
                      [source_file, source_line].compact.join(':')
                    end

      payload = [exception_class.to_s, normalized_message, first_frame].join('|')
      Digest::SHA1.hexdigest(payload)
    end
  end
end
