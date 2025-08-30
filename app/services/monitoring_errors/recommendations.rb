# frozen_string_literal: true

module MonitoringErrors
  class Recommendations
    attr_reader :records, :paginator, :count, :limit

    def initialize(limit, page)
      base_scope = MonitoringRecommendation.all
      @limit = limit
      @count = base_scope.count
      @paginator = Redmine::Pagination::Paginator.new(@count, @limit, page)
      @records = build_records(base_scope)
    end

    private

    def build_records(scope)
      scope.order(created_at: :desc)
           .offset(@paginator.offset)
           .limit(@paginator.per_page)
    end
  end
end
