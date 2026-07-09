# frozen_string_literal: true

require File.expand_path('../../test_helper', __dir__)
require File.expand_path('../../../lib/redmine_monitoring/constants', __dir__)
require File.expand_path('../../../lib/redmine_monitoring/data_sanitizer', __dir__)

module RedmineMonitoring
  class DataSanitizerTest < ActiveSupport::TestCase
    test 'masks sensitive keys recursively' do
      payload = {
        'password' => 'secret',
        'nested' => {
          'api_token' => 'token',
          'safe' => 'value'
        }
      }

      masked = DataSanitizer.mask(payload)

      assert_equal DataSanitizer::MASK, masked['password']
      assert_equal DataSanitizer::MASK, masked['nested']['api_token']
      assert_equal 'value', masked['nested']['safe']
    end

    test 'truncates serialized params by configured default limit' do
      json = DataSanitizer.truncate_json({ value: 'abcdef' }, 10)

      assert_operator json.bytesize, :<=, 10
    end

    test 'truncates backtrace strings' do
      assert_equal 'abc', DataSanitizer.truncate_string('abcdef', 3)
    end
  end
end
