class MonitoringRecommendation < ApplicationRecord
  belongs_to :user, optional: true

  validates :source, :category, :kind, :message, :fingerprint, presence: true
  scope :bullet, -> { where(source: 'bullet') }

  def self.fingerprint_for(kind:, klass:, association:, path:, query: nil)
    raw = [kind, klass, association, path, query].compact.join('|')
    Digest::SHA1.hexdigest(raw)
  end
end
