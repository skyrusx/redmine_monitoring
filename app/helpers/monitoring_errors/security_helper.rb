# frozen_string_literal: true

module MonitoringErrors
  module SecurityHelper
    include MonitoringErrors::SecurityView::WarningsHelper
    include MonitoringErrors::SecurityView::CodeBlockHelper
    include MonitoringErrors::SecurityView::FormattingHelper
  end
end
