# frozen_string_literal: true

class MonitoringSecurityWarning < ActiveRecord::Base
  belongs_to :monitoring_security_scan

  validates :warning_type, :fingerprint, :check_name, :message, :file, presence: true

  scope :by_type, ->(type) { where(warning_type: type) }
  scope :by_check, ->(name) { where(check_name: name) }
  scope :by_confidence, ->(level) { where(confidence: level) }
  scope :high, -> { where(confidence: 0) }
  scope :medium, -> { where(confidence: 1) }
  scope :weak, -> { where(confidence: 2) }
  scope :controllers, -> { where(path_match_sql('file', '(^|/)(plugins/[^/]+/)?app/controllers/')) }
  scope :models, -> { where(path_match_sql('file', '(^|/)(plugins/[^/]+/)?app/models/')) }
  scope :templates, lambda {
    where(
      "#{path_match_sql('file', '(^|/)(plugins/[^/]+/)?app/views/')} OR #{render_path_present_sql}"
    )
  }

  def self.path_match_sql(column, pattern)
    quoted_column = connection.quote_column_name(column)
    quoted_pattern = connection.quote(pattern)

    if connection.adapter_name.match?(/PostgreSQL/i)
      "COALESCE(#{quoted_column}, '') ~* #{quoted_pattern}"
    elsif connection.adapter_name.match?(/Mysql/i)
      "COALESCE(#{quoted_column}, '') REGEXP #{quoted_pattern}"
    else
      like_pattern = pattern.include?('controllers') ? '%app/controllers/%' :
                     pattern.include?('models') ? '%app/models/%' : '%app/views/%'
      "LOWER(COALESCE(#{quoted_column}, '')) LIKE #{connection.quote(like_pattern)}"
    end
  end

  def self.render_path_present_sql
    if connection.adapter_name.match?(/PostgreSQL/i)
      "render_path IS NOT NULL AND json_array_length(render_path) > 0"
    elsif connection.adapter_name.match?(/Mysql/i)
      'render_path IS NOT NULL AND JSON_LENGTH(render_path) > 0'
    else
      "render_path IS NOT NULL AND render_path NOT IN ('[]', '')"
    end
  end
end
