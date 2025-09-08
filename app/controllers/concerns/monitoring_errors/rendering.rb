# frozen_string_literal: true

module MonitoringErrors
  module Rendering
    extend ActiveSupport::Concern
    include RedmineMonitoring::Constants

    private

    def render_dashboard
      @dashboard = MonitoringErrors::Dashboard.new
    end

    def render_metrics
      @metrics = MonitoringErrors::Metrics.new(@base_scope[:metrics], per_page_param, params[:page])

      respond_to do |format|
        format.html
        AVAILABLE_EXPORT_FORMATS.each do |export_format|
          format.public_send(export_format) do
            MonitoringErrors::Exporter.new(@base_scope[:metrics]).send(export_format, self)
          end
        end
      end
    end

    def render_groups
      @groups = MonitoringErrors::Grouper.new(@base_scope[:errors], per_page_param, params[:page])
    end

    def render_recommendations
      render_404 unless monitoring_dev_mode?
      @recommendations = MonitoringErrors::Recommendations.new(@base_scope[:recommendations], per_page_param, params[:page])

      respond_to do |format|
        format.html
        AVAILABLE_EXPORT_FORMATS.each do |export_format|
          format.public_send(export_format) do
            MonitoringErrors::Exporter.new(@base_scope[:recommendations]).send(export_format, self)
          end
        end
      end
    end

    def render_alerts
      @alerts = MonitoringErrors::Alerts.new(per_page_param, params[:page])
    end

    def render_security
      @security_scans = MonitoringErrors::Security.new(per_page_param, params[:page])
    end

    def render_list_with_exports
      @lister = MonitoringErrors::Lister.new(@base_scope[:errors], per_page_param, params[:page])

      respond_to do |format|
        format.html
        AVAILABLE_EXPORT_FORMATS.each do |export_format|
          format.public_send(export_format) do
            MonitoringErrors::Exporter.new(@base_scope[:errors]).send(export_format, self)
          end
        end
      end
    end
  end
end
