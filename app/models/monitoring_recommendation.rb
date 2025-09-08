class MonitoringRecommendation < ApplicationRecord
  belongs_to :user, optional: true

  validates :source, :category, :kind, :message, :fingerprint, presence: true

  scope :by_controller_name, ->(value) { where(controller_name: value) if value.present? }
  scope :by_action_name, ->(value) { where(action_name: value) if value.present? }
  scope :by_category, ->(value) { where(category: value) if value.present? }
  scope :by_kind, ->(value) { where(kind: value) if value.present? }
  scope :by_user, ->(value) { where(user_id: value) if value.present? }
  scope :by_source, ->(value) { where(source: value) if value.present? }
  scope :bullet, -> { where(source: 'bullet') }
  scope :by_message, lambda { |value|
    if value.present?
      adapter = connection.adapter_name
      adapter.match?(/PostgreSQL/i) ? where('message ILIKE ?', "%#{value}%") : where('message LIKE ?', "%#{value}%")
    end
  }
  scope :created_from, ->(date) { where('created_at >= ?', date.to_date.beginning_of_day) if date.present? }
  scope :created_to, ->(date) { where('created_at <= ?', date.to_date.end_of_day) if date.present? }

  def self.filter(params)
    all.by_controller_name(params[:controller_name])
       .by_action_name(params[:action_name])
       .by_category(params[:category])
       .by_kind(params[:kind])
       .by_user(params[:user])
       .by_source(params[:source])
       .by_message(params[:message])
       .created_from(params[:created_at_from])
       .created_to(params[:created_at_to])
  end

  def self.fingerprint_for(kind:, klass:, association:, path:, query: nil)
    raw = [kind, klass, association, path, query].compact.join('|')
    Digest::SHA1.hexdigest(raw)
  end
end
