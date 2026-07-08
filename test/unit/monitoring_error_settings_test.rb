# frozen_string_literal: true

require File.expand_path('../test_helper', __dir__)

class MonitoringErrorSettingsTest < ActiveSupport::TestCase
  test 'valid_formats keeps supported formats and normalizes case' do
    formats = MonitoringError.send(:valid_formats, %w[html json invalid])

    assert_equal %w[HTML JSON], formats
  end

  test 'valid_formats returns nil when no supported formats are provided' do
    assert_nil MonitoringError.send(:valid_formats, %w[invalid unknown])
  end

  test 'allow_format checks against enabled formats case-insensitively' do
    MonitoringError.stub(:enabled_formats, %w[HTML JSON]) do
      assert MonitoringError.allow_format?(:json)
      assert MonitoringError.allow_format?('HTML')
      refute MonitoringError.allow_format?('xml')
    end
  end
end
