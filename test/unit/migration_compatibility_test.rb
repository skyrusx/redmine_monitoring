# frozen_string_literal: true

require File.expand_path('../test_helper', __dir__)

class MigrationCompatibilityTest < ActiveSupport::TestCase
  MIGRATION_FILES = Dir[File.expand_path('../../db/migrate/*.rb', __dir__)].freeze

  test 'migrations avoid PostgreSQL-only jsonb column declarations' do
    offenders = MIGRATION_FILES.select { |path| File.read(path).match?(/\bjsonb\b/) }

    assert_empty offenders
  end

  test 'json migration columns avoid database defaults for MySQL compatibility' do
    offenders = MIGRATION_FILES.select do |path|
      File.read(path).match?(/\b(?:t|table)\.json\b.*\bdefault:/)
    end

    assert_empty offenders
  end

  test 'security warning scopes use adapter-aware SQL for database-specific operations' do
    source = File.read(File.expand_path('../../app/models/monitoring_security_warning.rb', __dir__))

    assert_match(/adapter_name\.match\?\(\/PostgreSQL\/i\)/, source)
    assert_match(/adapter_name\.match\?\(\/Mysql\/i\)/, source)
    refute_match(/jsonb_array_length/, source)
  end
end
