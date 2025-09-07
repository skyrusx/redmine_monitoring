# frozen_string_literal: true

module MonitoringErrors
  module Exporters
    class PdfExporter
      def initialize(records, batch_size, attributes)
        @records = records
        @batch_size = batch_size
        @attributes = attributes
      end

      def call
        Prawn::Document.new do |pdf|
          setup_fonts(pdf)
          render_title(pdf)

          @records.find_in_batches(batch_size: @batch_size) do |batch|
            batch.each { |record| render_row(pdf, record) }
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
        user_ids = @records.distinct.pluck(:user_id).compact
        return if user_ids.empty?

        User.where(id: user_ids).order(:login).to_h { |user| [user.id, user.name] }
      end

      def render_row(pdf, record)
        @attributes.each do |attr|
          value = attr == 'user_id' ? preload_users[record.public_send(attr)] : record.public_send(attr)
          pdf.text [I18n.t("label_pdf_#{attr}"), value].join(': ')
        end

        pdf.move_down 10
        pdf.stroke_horizontal_rule
        pdf.move_down 10
      end
    end
  end
end
