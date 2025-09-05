# frozen_string_literal: true

module MonitoringErrors
  class Security
    attr_reader :records, :paginator, :count, :limit, :high_confidence_count

    def initialize(limit, page)
      base_scope = MonitoringSecurityScan.all
      @limit = limit
      @count = base_scope.count
      @paginator = Redmine::Pagination::Paginator.new(@count, @limit, page)
      @records = build_records(base_scope)
      @high_confidence_count = MonitoringSecurityWarning.where(confidence: 'High').count
    end

    private

    def build_records(scope)
      scope.order(created_at: :desc)
           .offset(@paginator.offset)
           .limit(@paginator.per_page)
    end
  end
end
