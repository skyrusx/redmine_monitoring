# frozen_string_literal: true

module MonitoringErrors
  class Recommendations
    attr_reader :records, :paginator, :count, :limit, :offset, :filters

    def initialize(base_scope, limit, page)
      @limit = limit
      @count = base_scope.count
      @paginator = Redmine::Pagination::Paginator.new(@count, @limit, page)
      @records = build_records(base_scope)
      @filters = build_filters
    end

    private

    def build_records(scope)
      scope.includes(:user)
           .order(created_at: :desc)
           .offset(@paginator.offset)
           .limit(@paginator.per_page)
    end

    def build_filters
      {
        controller_names: controller_names,
        action_names: action_names,
        categories: categories,
        kinds: kinds,
        users: users,
        sources: sources
      }
    end

    def controller_names
      MonitoringRecommendation.distinct.pluck(:controller_name).compact.sort
    end

    def action_names
      MonitoringRecommendation.distinct.pluck(:action_name).compact.sort
    end

    def categories
      categories = MonitoringRecommendation.distinct.pluck(:category).compact.sort
      categories.map { |category| [I18n.t("label_reco_categories.#{category}"), category] }
    end

    def kinds
      kinds = MonitoringRecommendation.distinct.pluck(:kind).compact.sort
      kinds.map { |kind| [I18n.t("label_reco_kinds.#{kind}"), kind] }
    end

    def users
      user_ids = MonitoringRecommendation.distinct.pluck(:user_id).compact
      return [] if user_ids.empty?

      User.where(id: user_ids).order(:login).to_a
    end

    def sources
      MonitoringRecommendation.distinct.pluck(:source).compact.sort
    end
  end
end
