class MonitoringError < ActiveRecord::Base
  belongs_to :user, optional: true

  validates :error_class, presence: true
  validates :message, presence: true

  USEFUL_HEADERS = %w[HTTP_USER_AGENT HTTP_REFERER HTTP_ACCEPT HTTP_ACCEPT_LANGUAGE HTTP_X_REQUESTED_WITH].freeze

  def location
    [controller_name, action_name].join("#")
  end
end
