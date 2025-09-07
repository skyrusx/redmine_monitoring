# frozen_string_literal: true

module MonitoringRequestScopes
  extend ActiveSupport::Concern

  included do
    scope :latest_order, -> { order(created_at: :desc, id: :desc) }
  end
end
