require 'simplecov'

require 'vcr'

RSpec.configure do |config|
  config.order = "random"

  config.backtrace_exclusion_patterns = []

  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end
end

VCR.configure do |c|
  c.cassette_library_dir = 'spec/fixtures/cassettes'
  c.hook_into :webmock
  c.configure_rspec_metadata!
  c.default_cassette_options = {:record => :new_episodes}
  c.allow_http_connections_when_no_cassette = true

  c.ignore_request do |r|
    elastic_config = YAML.load_file("config/database.yml")["test"]["elastic"]
    uri = URI.parse(r.uri)
    elastic_config["host"] == uri.host && elastic_config["port"] == uri.port
  end
end
