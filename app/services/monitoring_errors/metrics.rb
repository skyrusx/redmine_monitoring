# frozen_string_literal: true

module MonitoringErrors
  class Metrics
    attr_reader :records, :paginator, :count, :limit, :offset

    def initialize(limit, page)
      scope = MonitoringRequest.order(created_at: :desc)

      @limit = limit
      @count = scope.count
      @paginator = Redmine::Pagination::Paginator.new(@count, @limit, page)
      @offset = @paginator.offset

      @records = scope.offset(@offset).limit(@paginator.per_page)
    end
  end
end
