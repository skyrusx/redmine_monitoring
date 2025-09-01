module RedmineMonitoring
  module Notifications
    module Fingerprint
      def self.build(error)
        raw = [
          error.error_class,
          "#{error.controller_name}##{error.action_name}",
          error.status_code,
          error.format,
          error.message.to_s[0, 200]
        ].map(&:to_s).join('|')

        Digest::SHA1.hexdigest(raw)
      end
    end
  end
end
