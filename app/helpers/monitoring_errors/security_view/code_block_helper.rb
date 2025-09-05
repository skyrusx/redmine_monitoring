# frozen_string_literal: true

require 'set'

module MonitoringErrors
  module SecurityView
    module CodeBlockHelper
      def code_block(code, highlight: [], lang: 'ruby', start_line: 1)
        source_lines = code.to_s.lines
        highlighted_set = Set.new(Array(highlight).flatten.map(&:to_i))

        content_tag(:div, class: "mm-code mm-lang-#{lang}") do
          content_tag(:table, class: 'mm-code__table') do
            safe_join(
              source_lines.each_with_index.map do |line_text, index|
                line_number = start_line + index
                build_code_row(line_text, line_number, highlighted_set)
              end
            )
          end
        end
      end

      def code_block_from_file(file:, line:, context: 3, lang: 'ruby', fallback: nil)
        highlight_lines = Array(line).map(&:to_i).uniq
        absolute_path = resolve_absolute_path(file)

        if (file_lines = read_file_lines(absolute_path))
          from_index, to_index = compute_window(highlight_lines, file_lines.length, context)
          selected_lines = file_lines[from_index..to_index] || []
          return code_block(selected_lines.join,
                            highlight: highlight_lines,
                            lang: lang,
                            start_line: from_index + 1)
        end

        fallback_code = fallback.to_s.presence || ''
        code_block(fallback_code,
                   highlight: [1],
                   lang: lang,
                   start_line: highlight_lines.first.to_i)
      end

      private

      def resolve_absolute_path(file)
        root_path = Rails.root.to_s
        path = file.to_s
        path.start_with?('/', root_path) ? path : File.join(root_path, path)
      end

      def read_file_lines(absolute_path)
        return unless File.file?(absolute_path) && File.readable?(absolute_path)

        File.read(absolute_path, mode: 'r:UTF-8').lines
      end

      def compute_window(highlight_lines, total_length, context)
        first = [highlight_lines.min.to_i, 1].max
        from = (first - 1 - context).clamp(0, total_length - 1)
        last = highlight_lines.max.to_i
        to = (last - 1 + context).clamp(from, total_length - 1)
        [from, to]
      end

      def build_code_row(line_text, line_number, highlighted_set)
        row_classes = ['mm-code__row']
        row_classes << 'is-hit' if highlighted_set.include?(line_number)

        content_tag(:tr, class: row_classes.join(' '), 'data-line': line_number) do
          safe_join([
                      content_tag(:td, line_number, class: 'mm-code__gutter'),
                      content_tag(:td, line_text.chomp, class: 'mm-code__cell')
                    ])
        end
      end
    end
  end
end
