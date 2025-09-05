# frozen_string_literal: true

module RedmineMonitoring
  module Constants
    CHANNEL_STATUSES = {
      new: { label: 'Новый', css: 'status-new' },
      processing: { label: 'В обработке', css: 'status-processing' },
      delivered: { label: 'Доставлено', css: 'status-delivered' },
      failed: { label: 'Ошибка', css: 'status-failed' }
    }.freeze

    HTTP_STATUS_TEXT = {
      100 => 'Continue',
      101 => 'Switching Protocols',
      102 => 'Processing',
      103 => 'Early Hints',

      200 => 'OK',
      201 => 'Created',
      202 => 'Accepted',
      203 => 'Non-Authoritative Information',
      204 => 'No Content',
      205 => 'Reset Content',
      206 => 'Partial Content',
      207 => 'Multi-Status',
      208 => 'Already Reported',
      226 => 'IM Used',

      300 => 'Multiple Choices',
      301 => 'Moved Permanently',
      302 => 'Found',
      303 => 'See Other',
      304 => 'Not Modified',
      305 => 'Use Proxy',
      307 => 'Temporary Redirect',
      308 => 'Permanent Redirect',

      400 => 'Bad Request',
      401 => 'Unauthorized',
      403 => 'Forbidden',
      404 => 'Not Found',
      405 => 'Method Not Allowed',
      408 => 'Request Timeout',
      422 => 'Unprocessable Entity',
      429 => 'Too Many Requests',

      500 => 'Internal Server Error',
      502 => 'Bad Gateway',
      503 => 'Service Unavailable',
      504 => 'Gateway Timeout'
    }.freeze
  end
end
