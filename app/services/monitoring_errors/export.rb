require 'prawn'
require 'axlsx'

class MonitoringErrors::Export
  def initialize(errors, batch_size: 1000, locale: :ru)
    @errors = errors
    @batch_size = batch_size
    @attributes = MonitoringError.attribute_names
    @locale = locale
  end

  def to_csv
    Redmine::Export::CSV.generate(headers: true, encoding: 'UTF-8', col_sep: ';') do |csv|
      csv << @attributes.map { |attr| I18n.t("label_#{attr}", locale: @locale) }

      @errors.find_in_batches(batch_size: @batch_size) do |batch|
        batch.each do |error|
          csv << @attributes.map { |attr| error.public_send(attr) }
        end
      end
    end
  end

  def to_json
    @errors.find_in_batches(batch_size: @batch_size).flat_map do |batch|
      batch.map { |error| error.as_json(only: @attributes) }
    end.to_json
  end

  def to_pdf
    Prawn::Document.new do |pdf|
      font_path = Rails.root.join("plugins", "redmine_monitoring", "assets", "fonts", "Roboto", "Roboto.ttf")
      if File.exist?(font_path)
        pdf.font_families.update("Roboto" => { normal: font_path.to_s })
        pdf.font "Roboto"
      end

      pdf.text I18n.t(:label_pdf_title), size: 18, style: :normal, align: :center
      pdf.move_down 20

      users = User.where(id: @errors.where.not(user_id: nil).select(:user_id).distinct).pluck(:id, :login).to_h

      @errors.find_in_batches(batch_size: @batch_size) do |batch|
        batch.each do |row|
          pdf.text I18n.t(:label_pdf_section_main)
          pdf.text "#{I18n.t(:label_pdf_id)}: ##{row.id}"
          pdf.text "#{I18n.t(:label_pdf_created_at)}: #{row.created_at.strftime('%Y-%m-%d %H:%M:%S')}"
          pdf.text "#{I18n.t(:label_pdf_severity)}: #{row.severity}"
          pdf.text "#{I18n.t(:label_pdf_http_status)}: #{row.status_code}"
          pdf.move_down 6

          pdf.text I18n.t(:label_pdf_section_error)
          pdf.text "#{I18n.t(:label_pdf_error_class)}: #{row.error_class}"
          pdf.text "#{I18n.t(:label_pdf_exception_class)}: #{row.exception_class}"
          pdf.text "#{I18n.t(:label_pdf_message)}: #{row.message}"
          pdf.move_down 6

          pdf.text I18n.t(:label_pdf_section_location)
          pdf.text "#{I18n.t(:label_pdf_controller_action)}: #{row.controller_name}##{row.action_name}"
          pdf.text "#{I18n.t(:label_pdf_file_line)}: #{row.file} : #{row.line}"
          pdf.move_down 6

          pdf.text I18n.t(:label_pdf_section_user_env)
          pdf.text "#{I18n.t(:label_pdf_user)}: #{users[row.user_id] || row.user_id || '-'}"
          pdf.text "#{I18n.t(:label_pdf_env)}: #{row.env}"
          pdf.text "#{I18n.t(:label_pdf_format)}: #{row.format}"
          pdf.text "#{I18n.t(:label_pdf_ip)}: #{row.ip_address}"
          pdf.text "#{I18n.t(:label_pdf_user_agent)}: #{row.user_agent}"
          pdf.text "#{I18n.t(:label_pdf_referer)}: #{row.referer}"
          pdf.move_down 6

          pdf.text I18n.t(:label_pdf_section_request_data)
          pdf.text "#{I18n.t(:label_pdf_params)}: #{row.params}"
          pdf.text "#{I18n.t(:label_pdf_headers)}: #{row.headers}"
          pdf.move_down 6

          pdf.text I18n.t(:label_pdf_section_backtrace)
          pdf.text "#{I18n.t(:label_pdf_full_backtrace)}:\n#{row.backtrace}"
          pdf.move_down 10

          pdf.stroke_horizontal_rule
          pdf.move_down 10
        end
      end
    end.render
  end

  def to_xlsx
    package = Axlsx::Package.new
    workbook = package.workbook

    workbook.add_worksheet(name: "Monitoring Errors") do |sheet|
      styles = workbook.styles
      header_style = styles.add_style(b: true, alignment: { horizontal: :center })
      cell_style = styles.add_style(alignment: { horizontal: :left, vertical: :top })
      datetime_style = styles.add_style(format_code: 'yyyy-mm-dd hh:mm:ss')

      date_cols = %w[created_at updated_at]

      headers = @attributes.map { |a| I18n.t("label_#{a}", locale: @locale, default: a.to_s.humanize) }
      sheet.add_row headers, style: header_style

      column_styles = @attributes.map { |attr| date_cols.include?(attr) ? datetime_style : cell_style }
      users = User.where(id: @errors.where.not(user_id: nil).select(:user_id).distinct).pluck(:id, :login).to_h

      @errors.find_in_batches(batch_size: @batch_size) do |batch|
        batch.each do |row|
          values = @attributes.map { |attr| attr == 'user_id' ? (users[row.user_id] || row.user_id) : row.public_send(attr) }
          sheet.add_row values, style: column_styles
        end
      end

      sheet.auto_filter = "A1:#{Axlsx::col_ref(@attributes.size - 1)}1"
      sheet.sheet_view.show_grid_lines = false
    end

    data = package.to_stream.read
    data.force_encoding(Encoding::BINARY)
    data
  end
end
