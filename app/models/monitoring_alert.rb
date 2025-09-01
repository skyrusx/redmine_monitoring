class MonitoringAlert < ApplicationRecord
  has_many :monitoring_alert_channels, dependent: :destroy
  alias channels monitoring_alert_channels

  def payload
    last_error = MonitoringError.find_by(id: last_error_id)
    return {} unless last_error

    RedmineMonitoring::Notifications::PayloadBuilder.new(last_error).call
  end
end
