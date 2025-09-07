# frozen_string_literal: true

module MonitoringErrors
  class Grouper
    attr_reader :records, :paginator, :count, :limit

    def initialize(base_scope, limit, page)
      @limit = limit
      groups = build_scope(base_scope)
      @count = groups.except(:select, :order).count.size
      @paginator = Redmine::Pagination::Paginator.new(@count, @limit, page)
      @records = groups.order('count DESC, last_seen_at DESC')
                       .offset(@paginator.offset)
                       .limit(@paginator.per_page)
    end

    private

    def build_scope(base_scope)
      adapter = ActiveRecord::Base.connection.adapter_name.downcase
      first_frame_sql = if adapter.include?('postgres')
                          "substring(backtrace from '^[^\\n]+')"
                        else
                          "SUBSTRING_INDEX(backtrace, '\n', 1)"
                        end

      select_fields = [
        'exception_class',
        'message',
        "#{first_frame_sql} AS first_frame",
        'COUNT(*) AS count',
        'MIN(created_at) AS first_seen_at',
        'MAX(created_at) AS last_seen_at',
        'MIN(error_class) AS error_class'
      ]

      group_columns = %w[exception_class message] << first_frame_sql

      base_scope.select(select_fields.join(', ')).group(group_columns.join(', '))
    end
  end
end
