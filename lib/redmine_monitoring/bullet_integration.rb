# frozen_string_literal: true

require 'bullet'
require 'uniform_notifier'
require_relative 'bullet_integration/io_adapter'
require_relative 'bullet_integration/notifier'

module RedmineMonitoring
  module BulletIntegration
    # Контекст текущего запроса (заполняется в middleware и через Notifications)
    class Current < ActiveSupport::CurrentAttributes
      attribute :controller_name, :action_name, :path, :user_id
      resets { self.controller_name = self.action_name = self.path = self.user_id = nil }
    end

    class << self
      def enable?
        settings = Setting.plugin_redmine_monitoring || {}
        ActiveModel::Type::Boolean.new.cast(settings['dev_mode'] || settings[:dev_mode])
      rescue StandardError
        false
      end

      def attach!
        return unless enable?
        return if @attached

        configure_bullet!
        install_custom_notifier!
        install_notifications!

        @attached = true
      end

      private

      def configure_bullet!
        Bullet.enable = true
        Bullet.n_plus_one_query_enable = true
        Bullet.unused_eager_loading_enable = true
        Bullet.counter_cache_enable = true

        # пишем только в наш кастомный notifier
        Bullet.rails_logger = false
        Bullet.bullet_logger = false
        Bullet.console = false
        Bullet.add_footer = false
      end

      def install_custom_notifier!
        UniformNotifier.customized_logger = IoAdapter.new
      end

      # Подписка на начало/конец обработки контроллера: дополняем controller/action/path и user_id
      def install_notifications!
        # начало обработки — заполняем controller/action; path (если пуст)
        ActiveSupport::Notifications.subscribe('start_processing.action_controller') do |*_args, payload|
          cur = RedmineMonitoring::BulletIntegration::Current
          cur.controller_name = payload[:controller].to_s
          cur.action_name = payload[:action].to_s
          cur.path ||= payload[:path].presence || build_path_from(payload)
        end

        # конец обработки — user уже определён; зафиксируем user_id
        ActiveSupport::Notifications.subscribe('process_action.action_controller') do |*_args|
          cur = RedmineMonitoring::BulletIntegration::Current
          user = User.current
          cur.user_id = user.id if user && !(user.respond_to?(:anonymous?) && user.anonymous?)
        end
      end

      def build_path_from(payload)
        params = payload[:params] || {}
        controller = params[:controller] || params['controller']
        action = params[:action] || params['action']
        "/#{controller}/#{action}"
      rescue StandardError
        ''
      end
    end
  end
end
