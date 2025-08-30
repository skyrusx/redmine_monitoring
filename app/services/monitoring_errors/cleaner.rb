# frozen_string_literal: true

module MonitoringErrors
  class Cleaner
    include RedmineMonitoring::Constants

    def self.call(tab)
      case tab
      when 'errors'  then MonitoringError.in_batches(of: DEFAULT_BATCH_SIZE).delete_all
      when 'metrics' then MonitoringRequest.in_batches(of: DEFAULT_BATCH_SIZE).delete_all
      end
    end
  end
end
