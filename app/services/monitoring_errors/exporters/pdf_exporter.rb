# frozen_string_literal: true

module MonitoringErrors
  module Exporters
    class PdfExporter
      def initialize(errors, batch_size, attributes)
        @errors = errors
        @batch_size = batch_size
        @attributes = attributes
      end

      def call
        Prawn::Document.new do |pdf|
          setup_fonts(pdf)
          render_title(pdf)
          users = preload_users

          @errors.find_in_batches(batch_size: @batch_size) do |batch|
            batch.each { |row| render_row(pdf, row, users) }
          end
        end.render
      end

      private

      def setup_fonts(pdf)
        font_path = Rails.root.join('plugins/redmine_monitoring/assets/fonts/Roboto/Roboto.ttf')
        return unless File.exist?(font_path)

        pdf.font_families.update('Roboto' => { normal: font_path.to_s })
        pdf.font 'Roboto'
      end

      def render_title(pdf)
        pdf.text I18n.t('label_pdf_title'), size: 18, align: :center
        pdf.move_down 20
      end

      def preload_users
        User.where(id: @errors.where.not(user_id: nil).select(:user_id).distinct)
            .pluck(:id, :login)
            .to_h
      end

      def render_row(pdf, row, users)
        render_main(pdf, row)
        render_error_info(pdf, row)
        render_location(pdf, row)
        render_user_env(pdf, row, users)
        render_request_data(pdf, row)
        render_backtrace(pdf, row)

        pdf.stroke_horizontal_rule
        pdf.move_down 10
      end

      def render_main(pdf, row)
        pdf.text I18n.t('label_pdf_section_main')
        pdf.text "#{I18n.t('label_pdf_id')}: ##{row.id}"
        pdf.text "#{I18n.t('label_pdf_created_at')}: #{row.created_at.strftime('%Y-%m-%d %H:%M:%S')}"
        pdf.text "#{I18n.t('label_pdf_severity')}: #{row.severity}"
        pdf.text "#{I18n.t('label_pdf_http_status')}: #{row.status_code}"
        pdf.move_down 6
      end

      def render_error_info(pdf, row)
        pdf.text I18n.t('label_pdf_section_error')
        pdf.text "#{I18n.t('label_pdf_error_class')}: #{row.error_class}"
        pdf.text "#{I18n.t('label_pdf_exception_class')}: #{row.exception_class}"
        pdf.text "#{I18n.t('label_pdf_message')}: #{row.message}"
        pdf.move_down 6
      end

      def render_location(pdf, row)
        pdf.text I18n.t('label_pdf_section_location')
        pdf.text "#{I18n.t('label_pdf_controller_action')}: #{row.controller_name}##{row.action_name}"
        pdf.text "#{I18n.t('label_pdf_file_line')}: #{row.file} : #{row.line}"
        pdf.move_down 6
      end

      def render_user_env(pdf, row, users)
        pdf.text I18n.t('label_pdf_section_user_env')
        pdf.text "#{I18n.t('label_pdf_user')}: #{users[row.user_id] || row.user_id || '-'}"
        pdf.text "#{I18n.t('label_pdf_env')}: #{row.env}"
        pdf.text "#{I18n.t('label_pdf_format')}: #{row.format}"
        pdf.text "#{I18n.t('label_pdf_ip')}: #{row.ip_address}"
        pdf.text "#{I18n.t('label_pdf_user_agent')}: #{row.user_agent}"
        pdf.text "#{I18n.t('label_pdf_referer')}: #{row.referer}"
        pdf.move_down 6
      end

      def render_request_data(pdf, row)
        pdf.text I18n.t('label_pdf_section_request_data')
        pdf.text "#{I18n.t('label_pdf_params')}: #{row.params}"
        pdf.text "#{I18n.t('label_pdf_headers')}: #{row.headers}"
        pdf.move_down 6
      end

      def render_backtrace(pdf, row)
        pdf.text I18n.t('label_pdf_section_backtrace')
        pdf.text "#{I18n.t('label_pdf_full_backtrace')}:\n#{row.backtrace}"
        pdf.move_down 10
      end
    end
  end
end
