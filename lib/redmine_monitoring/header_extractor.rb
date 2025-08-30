# frozen_string_literal: true

module RedmineMonitoring
  class HeaderExtractor
    def initialize(payload)
      @raw_headers = payload[:headers]
    end

    def extract
      headers = to_headers_hash(@raw_headers)
      request = request_object(@raw_headers)

      ip = detected_ip(headers, request)
      user_agent = first_present(headers['HTTP_USER_AGENT'], request&.user_agent).to_s
      referer = first_present(headers['HTTP_REFERER'], request&.referer).to_s
      bytes_sent = detected_bytes_sent(headers, request)

      { ip: ip, user_agent: user_agent, referer: referer, bytes_sent: bytes_sent }
    rescue StandardError
      { ip: nil, user_agent: nil, referer: nil, bytes_sent: 0 }
    end

    private

    def to_headers_hash(raw_headers)
      case raw_headers
      when Hash then raw_headers
      when ActionDispatch::Http::Headers then raw_headers.to_h
      else {}
      end
    end

    def request_object(raw_headers)
      return unless raw_headers.is_a?(ActionDispatch::Http::Headers)

      ActionDispatch::Request.new(raw_headers.env)
    end

    def first_present(*values)
      values.find(&:present?)
    end

    def detected_ip(headers, request)
      forwarded_for = headers['HTTP_X_FORWARDED_FOR']
      x_real_ip = headers['HTTP_X_REAL_IP']
      remote_addr = headers['REMOTE_ADDR']

      first_present(
        extract_first_ip(forwarded_for),
        x_real_ip,
        remote_addr,
        request&.remote_ip
      ).to_s
    end

    def extract_first_ip(forwarded_for)
      return if forwarded_for.blank?

      forwarded_for.to_s.split(',').map(&:strip).reject(&:blank?).first
    end

    def detected_bytes_sent(headers, request)
      header_len = headers['Content-Length'].to_i
      request_len = request&.content_length.to_i

      (header_len.positive? ? header_len : nil) ||
        (request_len.positive? ? request_len : nil) ||
        0
    end
  end
end
