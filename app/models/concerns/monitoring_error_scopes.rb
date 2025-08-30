# frozen_string_literal: true

module MonitoringErrorScopes
  extend ActiveSupport::Concern

  included do
    scope :latest_order, -> { order(created_at: :desc, id: :desc) }
    scope :by_exception_class, ->(value) { where(exception_class: value) if value.present? }
    scope :by_error_class, ->(value) { where(error_class: value) if value.present? }
    scope :by_controller_name, ->(value) { where(controller_name: value) if value.present? }
    scope :by_action_name, ->(value) { where(action_name: value) if value.present? }
    scope :by_user, ->(value) { where(user_id: value) if value.present? }
    scope :by_status, ->(value) { where(status_code: value) if value.present? }
    scope :by_error_format, ->(value) { where(format: value) if value.present? }
    scope :by_env, ->(value) { where(env: value) if value.present? }
    scope :by_severity, ->(value) { where(severity: value) if value.present? }
    scope :by_message, lambda { |value|
      if value.present?
        adapter = connection.adapter_name
        adapter.match?(/PostgreSQL/i) ? where('message ILIKE ?', "%#{value}%") : where('message LIKE ?', "%#{value}%")
      end
    }
    scope :created_from, ->(date) { where('created_at >= ?', date.to_date.beginning_of_day) if date.present? }
    scope :created_to, ->(date) { where('created_at <= ?', date.to_date.end_of_day) if date.present? }
  end

  class_methods do
    def filter(params)
      all.by_error_class(params[:error_class])
         .by_exception_class(params[:exception_class])
         .by_controller_name(params[:controller_name])
         .by_action_name(params[:action_name])
         .by_user(params[:user_id])
         .by_status(params[:status_code])
         .by_error_format(params[:error_format])
         .by_env(params[:env])
         .by_message(params[:message])
         .created_from(params[:created_at_from])
         .created_to(params[:created_at_to])
         .by_severity(params[:severity])
    end
  end
end
