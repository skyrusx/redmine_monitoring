# frozen_string_literal: true

module MonitoringRequestNormalize
  extend ActiveSupport::Concern
  include RedmineMonitoring::Constants

  class_methods do
    def normalize_path(path, method: :get, use_cache: !Rails.env.development?)
      return '' if path.blank?

      if use_cache
        cache_key = "monitoring:norm:v1:#{method.to_s.upcase}:#{path}"
        Rails.cache.fetch(cache_key, expires_in: CACHE_DAYS.day) do
          normalize_path_via_router(path, method) || normalize_path_fallback(path)
        end
      else
        # DEV-режим: без кэша, всегда «свежее» распознавание
        normalize_path_via_router(path, method) || normalize_path_fallback(path)
      end
    end

    def normalize_path_via_router(raw_path, method)
      path = raw_path.to_s.split('?').first
      env = Rack::MockRequest.env_for(path, method: method.to_s.upcase)
      req = ActionDispatch::Request.new(env)
      spec = nil

      Rails.application.routes.router.recognize(req) do |route, _params|
        spec = route.path.spec.to_s
        break
      end

      spec.presence
    rescue StandardError => e
      Rails.logger.debug { "[Monitoring] normalize_path_via_router failed: #{e.class}: #{e.message}" }
      nil
    end
  end

  class_methods do
    def normalize_path_fallback(path)
      path.to_s
          .gsub(%r{/\d+}, '/:id')
          .gsub(%r{/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}}i, '/:uuid')
          .gsub(%r{/[0-9a-f]{16,}}i, '/:hash')
          .gsub(%r{//+}, '/')
    end
  end
end
