# frozen_string_literal: true

module MonitoringErrors
  module Exporters
    class XlsxExporter
      include RedmineMonitoring::Constants

      def initialize(errors, batch_size, attributes, locale)
        @errors = errors
        @batch_size = batch_size
        @attributes = attributes
        @locale = locale
      end

      def call
        package = Axlsx::Package.new
        workbook = package.workbook

        workbook.add_worksheet(name: 'Monitoring Errors') do |sheet|
          styles = build_styles(workbook)
          add_headers(sheet, styles[:header])
          users = preload_users
          column_styles = build_column_styles(@attributes, styles)

          stream_rows(sheet, column_styles, users)
          finalize_sheet(sheet)
        end

        data = package.to_stream.read
        data.force_encoding(Encoding::BINARY)
        data
      end

      private

      def build_styles(workbook)
        styles = workbook.styles
        {
          header: styles.add_style(b: true, alignment: { horizontal: :center }),
          cell: styles.add_style(alignment: { horizontal: :left, vertical: :top }),
          datetime: styles.add_style(format_code: 'yyyy-mm-dd hh:mm:ss')
        }
      end

      def localized_headers
        @attributes.map { |attr| I18n.t("label_#{attr}", locale: @locale, default: attr.to_s.humanize) }
      end

      def add_headers(sheet, header_style)
        sheet.add_row localized_headers, style: header_style
      end

      def preload_users
        user_ids = @errors.where.not(user_id: nil).distinct.pluck(:user_id)
        User.where(id: user_ids).pluck(:id, :login).to_h
      end

      def build_column_styles(attributes, styles)
        attributes.map { |attr| DATE_COLUMNS.include?(attr) ? styles[:datetime] : styles[:cell] }
      end

      def stream_rows(sheet, column_styles, users)
        @errors.find_in_batches(batch_size: @batch_size) do |batch|
          batch.each { |row| sheet.add_row row_values(row, users), style: column_styles }
        end
      end

      def row_values(row, users)
        @attributes.map do |attr|
          attr == 'user_id' ? (users[row.user_id] || row.user_id) : row.public_send(attr)
        end
      end

      def finalize_sheet(sheet)
        sheet.auto_filter = "A1:#{Axlsx.col_ref(@attributes.size - 1)}1"
        sheet.sheet_view.show_grid_lines = false
      end
    end
  end
end
