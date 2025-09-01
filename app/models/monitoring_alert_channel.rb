class MonitoringAlertChannel < ApplicationRecord
  STATUSES = %w[new processing delivered failed].freeze

  belongs_to :monitoring_alert
  validates :channel, presence: true
  validates :status, inclusion: { in: STATUSES }

  def start!
    update_columns(status: 'processing')
  end

  def succeed!
    update_columns(
      status: 'delivered',
      sent_count: sent_count.to_i + 1,
      last_sent_at: Time.current,
      last_error: nil
    )
  end

  def fail!(error_message)
    update_columns(status: 'failed', last_error: error_message.to_s.presence)
  end
end
