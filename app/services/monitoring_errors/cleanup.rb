# frozen_string_literal: true

module MonitoringErrors
  class Cleanup
    include RedmineMonitoring::Constants

    Result = Struct.new(:target, :retention_days, :cutoff, :matched, :deleted, :dry_run, :batch_size, :skipped)

    TARGETS = {
      errors: { model: 'MonitoringError' },
      metrics: { model: 'MonitoringRequest' },
      recommendations: { model: 'MonitoringRecommendation' },
      security: { model: 'MonitoringSecurityScan' }
    }.freeze

    SECURITY_CHILD_MODELS = %w[
      MonitoringSecurityWarning
      MonitoringSecurityIgnoredWarning
      MonitoringSecurityError
      MonitoringSecurityObsolete
    ].freeze

    class << self
      def call(target:, days: nil, batch_size: nil, dry_run: false)
        new(target: target, days: days, batch_size: batch_size, dry_run: dry_run).call
      end

      def call_all(days: nil, batch_size: nil, dry_run: false)
        TARGETS.keys.map do |target|
          call(target: target, days: days, batch_size: batch_size, dry_run: dry_run)
        end
      end
    end

    def initialize(target:, days: nil, batch_size: nil, dry_run: false)
      @target = normalize_target(target)
      @days_override = positive_integer(days)
      @batch_size = positive_integer(batch_size) || DEFAULT_BATCH_SIZE
      @dry_run = ActiveModel::Type::Boolean.new.cast(dry_run)
    end

    def call
      model = model_for(target)
      days = days_for(model)

      return skipped_result(days) if days <= 0

      cutoff = Time.current - days.days
      scope = model.where(model.arel_table[:created_at].lt(cutoff))
      matched = scope.count
      deleted = dry_run ? 0 : delete_scope(scope)

      Result.new(target, days, cutoff, matched, deleted, dry_run, batch_size, false)
    end

    private

    attr_reader :target, :days_override, :batch_size, :dry_run

    def normalize_target(value)
      normalized = value.to_s.downcase.to_sym
      return normalized if TARGETS.key?(normalized)

      raise ArgumentError, "Unknown cleanup target: #{value}"
    end

    def model_for(target)
      Object.const_get(TARGETS.fetch(target).fetch(:model))
    end

    def days_for(model)
      days_override || (model.respond_to?(:retention_days) ? model.retention_days.to_i : 0)
    end

    def skipped_result(days)
      Result.new(target, days, nil, 0, 0, dry_run, batch_size, true)
    end

    def delete_scope(scope)
      deleted_total = 0

      loop do
        ids = scope.order(:created_at, :id).limit(batch_size).pluck(:id)
        break if ids.empty?

        deleted_total += delete_ids(ids)
      end

      deleted_total
    end

    def delete_ids(ids)
      return delete_security_scan_ids(ids) if target == :security

      model_for(target).where(id: ids).delete_all
    end

    def delete_security_scan_ids(ids)
      SECURITY_CHILD_MODELS.each do |class_name|
        Object.const_get(class_name).where(monitoring_security_scan_id: ids).delete_all
      end

      MonitoringSecurityScan.where(id: ids).delete_all
    end

    def positive_integer(value)
      integer = value.to_i
      integer.positive? ? integer : nil
    rescue StandardError
      nil
    end
  end
end
