require 'support/data_helper'
require 'support/xml_helper'

module TestHelper
  def self.setup
    DatabaseCleaner.clean_with :truncation
    DatabaseCleaner.strategy = :transaction

    system "cat /dev/null >| #{Rails.root}/log/test.log"

    XmlHelper.compile_validator

    Kor::Settings.purge_files!
    Kor::Settings.instance.ensure_fresh
    Kor.settings.update(
      'primary_relations' => ['shows'],
      'secondary_relations' => ['has been created by']
    )
    
    Delayed::Worker.delay_jobs = false
    Rails.application.load_seed
    DataHelper.default_setup relationships: true, pictures: true

    system "rm -rf #{Rails.root}/tmp/test.media.clone"
    system "mv #{Medium.media_data_dir} #{Rails.root}/tmp/test.media.clone"
  end

  def self.around_each(&block)
    begin
      DatabaseCleaner.start
      yield
      DatabaseCleaner.clean
    rescue ActiveRecord::RecordInvalid => e
      binding.pry
      p e.record.errors.full_messages
    end
  end

  def self.before_each(framework, scope, test)
    system "rm -rf #{Medium.media_data_dir}/"
    system "cp -a #{Rails.root}/tmp/test.media.clone #{Medium.media_data_dir}"
      
    FactoryGirl.reload
    Kor::Auth.sources(true)

    use_elastic = (
      framework == :rspec && test.metadata[:elastic] ||
      framework == :cucumber && test.tags.any?{|st| st.name == '@elastic'}
    )

    if use_elastic
      Kor::Elastic.enable
      Kor::Elastic.reset_index
      Kor::Elastic.index_all full: true
    else
      Kor::Elastic.disable
    end

    if framework == :rspec && test.metadata[:type].to_s == 'controller'
      scope.request.headers["accept"] = 'application/json'
    end

    ActionMailer::Base.deliveries.clear
    system "rm -rf #{Rails.root}/tmp/export_spec"
    
    Kor::Settings.purge_files!
    Kor::Settings.instance.ensure_fresh
    Kor.settings.update(
      'primary_relations' => ['shows'],
      'secondary_relations' => ['has been created by']
    )
  end

  def self.setup_vcr(framework)
    require 'vcr'

    VCR.configure do |c|
      c.cassette_library_dir = 'spec/fixtures/cassettes'
      c.hook_into :webmock

      if framework == :rspec
        c.configure_rspec_metadata!
      end

      c.default_cassette_options = {:record => :new_episodes}
      c.allow_http_connections_when_no_cassette = true

      c.ignore_request do |r|
        elastic_config = YAML.load_file('config/database.yml')['test']['elastic']
        uri = URI.parse(r.uri)

        uri.port == 7055 || (
          elastic_config["host"] == uri.host &&
          elastic_config["port"] == uri.port
        )
      end
    end
  end

  def self.setup_simplecov
    if ENV['COVERAGE'] == 'true'
      require 'simplecov'
    
      SimpleCov.start 'rails' do
        merge_timeout 3600
        coverage_dir 'tmp/coverage'
        track_files '{app,lib,config}/**/*.{rb,rake}'
      end
    
      puts "performing coverage analysis"
    end
  end
end