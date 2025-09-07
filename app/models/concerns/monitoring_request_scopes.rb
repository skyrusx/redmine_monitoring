# frozen_string_literal: true

module MonitoringRequestScopes
  extend ActiveSupport::Concern

  included do
    scope :by_normalized_path, ->(value) { where(normalized_path: value) if value.present? }
    scope :by_ip_address, ->(value) { where(ip_address: value) if value.present? }
    scope :by_method, ->(value) { where(method: value) if value.present? }
    scope :by_status_code, ->(value) { where(status_code: value) if value.present? }
    scope :by_user, ->(value) { where(user: value) if value.present? }
    scope :by_controller_name, ->(value) { where(controller_name: value) if value.present? }
    scope :by_action_name, ->(value) { where(action_name: value) if value.present? }
    scope :by_format, ->(value) { where(format: value) if value.present? }
    scope :by_env, ->(value) { where(env: value) if value.present? }
    scope :by_path, lambda { |value|
      if value.present?
        adapter = connection.adapter_name
        adapter.match?(/PostgreSQL/i) ? where('path ILIKE ?', "%#{value}%") : where('path LIKE ?', "%#{value}%")
      end
    }
    scope :created_from, ->(date) { where('created_at >= ?', date.to_date.beginning_of_day) if date.present? }
    scope :created_to, ->(date) { where('created_at <= ?', date.to_date.end_of_day) if date.present? }

    scope :latest_order, -> { order(created_at: :desc, id: :desc) }
  end

  class_methods do
    def filter(params)
      all.by_normalized_path(params[:normalized_path])
         .by_ip_address(params[:ip_address])
         .by_method(params[:method])
         .by_status_code(params[:status_code])
         .by_user(params[:user])
         .by_controller_name(params[:controller_name])
         .by_action_name(params[:action_name])
         .by_format(params[:format])
         .by_env(params[:env])
         .by_path(params[:path])
         .created_from(params[:created_at_from])
         .created_to(params[:created_at_to])
    end
  end
end
