# frozen_string_literal: true

module MonitoringErrors
  module SecurityView
    module FormattingHelper
      def norm_conf(confidence_value)
        normalized = confidence_value.to_s.strip.downcase

        case normalized
        when 'high', '0' then 0
        when 'medium', '1' then 1
        else 2
        end
      end
    end
  end
end
