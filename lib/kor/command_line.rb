class Kor::CommandLine

  def initialize(args)
    @args = args.dup
    @config = {
      :format => "excel",
      :username => "admin",
      :ignore_stale => false,
      :obey_permissions => false,
      :simulate => false,
      :ignore_validations => false,
      :collection_id => [],
      :kind_id => []
    }
    @required = []
    @command = nil

    @parser = OptionParser.new
  end

  def parse_options
    @parser.version = Kor.version
    @parser.banner = File.read("#{Rails.root}/config/banner.txt")

    @parser.on("--version", "print the version") { @command = "version" }
    @parser.on("-v", "--verbose", "run in verbose mode") { @config[:verbose] = true }
    @parser.on("-h", "--help", "print available options and commands") { @config[:help] = true }
    @parser.on("--debug", "the user to act as, default: admin") { @config[:debug] = true }
    @parser.on("--timestamp", "print a timestamp before doing anything") { @config[:timestamp] = true }
    @parser.separator ""

    @parser.order!(@args)

    @command ||= @args.shift

    if @command == "import" || @command == "export"
      
    end

    case @command
      when "export"
        @parser.on("-f FORMAT", "the format to use, supported values: [excel], default: excel") {|v| @config[:format] = v }
        @parser.on("--collection-id=IDS", "export only the given collections, may contain a comma separated list of ids") {|v| @config[:collection_id] = v.split(",").map{|v| v.to_i} }
        @parser.on("--kind-id=IDS", "export only the given kinds, may contain a comma separated list of ids") {|v| @config[:kind_id] = v.split(",").map{|v| v.to_i} }
        @required += [:format]
      when "import"
        @parser.on("-f FORMAT", "the format to use, supported values: [excel], default: excel") {|v| @config[:format] = v }
        @parser.on("-u USERAME", "the user to act as, default: admin") {|v| @config[:username] = v }
        @parser.on("-i", "write objects even if they are stale, default: false") { @config[:ignore_stale] = true }
        @parser.on("-p", "obey the permission system, default: false") { @config[:obey_permissions] = true }
        @parser.on("-s", "for imports: don't make any changes, default: false, implies verbose") { @config[:simulate] = true }
        @parser.on("-o", "ignore all validations") { @config[:ignore_validations] = true }
        @required += [:format]
      when "group-to-zip"
        @parser.on("--group-id=ID", "select the group to package") {|v| @config[:group_id] = v.to_i }
        @parser.on("--class-name=NAME", "select the group klass to package") {|v| @config[:class_name] = v }
        @required += [:group_id, :class_name]
      when "exif-stats"
        @parser.on("-f DATE", "the lower bound for the time period to consider (YYYY-MM-DD)") {|v| @config[:from] = v }
        @parser.on("-t DATE", "the upper bound for the time period to consider (YYYY-MM-DD)") {|v| @config[:to] = v }
        @required += [:from, :to]
      when 'list-permissions'
        @parser.on('-e ENTITY', 'the id of an entity to limit the result list to') {|v| @config[:entity_id] = v}
        @parser.on('-u USER', 'the id of a user to limit the result list to') {|v| @config[:user_id] = v}
    end

    @parser.order!(@args)

    if @config[:verbose]
      puts "command: #{@command}"
      puts "options: #{@config.inspect}"
    end
  end

  def validate
    @required.each do |r|
      if @config[r].nil?
        puts "please specify a value for '#{r}'"
        exit 1
      end
    end
  end

  def run
    if @config[:help]
      usage
    else
      validate

      if @config[:timestamp]
        puts Time.now
      end

      case @command
        when 'version' then version
        when 'export'
          if @config[:format] == 'excel'
            excel_export
          end
        when 'import'
          if @config[:format] == 'excel'
            excel_import
          end
        when 'reprocess-all' then reprocess_all
        when 'index-all' then index_all
        when 'group-to-zip' then group_to_zip
        when 'notify-expiring-users' then notify_expiring_users
        when 'recheck-invalid-entities' then recheck_invalid_entities
        when 'delete-expired-downloads' then delete_expired_downloads
        when 'editor-stats' then editor_stats
        when 'exif-stats' then exif_stats
        when 'reset-admin-account' then reset_admin_account
        when 'reset-guest-account' then reset_guest_account
        when 'to-neo' then to_neo
        when 'connect-random' then connect_random
        when 'cleanup-sessions' then cleanup_sessions
        when 'list-permissions' then list_permissions
        when 'cleanup-exception-logs' then cleanup_exception_logs
        when 'secrets' then secrets
        when 'consistency-check' then consistency_check
        when 'import-erlangen-crm' then import_erlangen_crm
        else
          puts "command '#{@command}' is not known"
          usage
      end
    end
  end

  def usage
    puts @parser
  end

  def version
    puts Kor.version
  end

  def excel_export
    dir = @args.shift
    Kor::Export::Excel.new(dir, @config).run
  end

  def excel_import
    dir = @args.shift
    Kor::Import::Excel.new(dir, @config).run
  end

  def reprocess_all
    num = Medium.count
    left = num
    started_at = nil
    puts "Found #{num} media entities"
    
    Medium.find_each do |m|
      started_at ||= Time.now
      
      m.image.reprocess! if m.image.file?
      
      left -= 1
      seconds_left = (Time.now - started_at).to_f / (num - left) * left
      puts "#{left} items left (ETA: #{Time.now + seconds_left.to_i})"
    end
  end

  def index_all
    Kor::Elastic.drop_index
    Kor::Elastic.create_index
    ActiveRecord::Base.logger.level = Logger::ERROR
    Kor::Elastic.index_all :full => true, :progress => true
  end

  def group_to_zip
    klass = @config[:class_name].constantize
    group_id = @config[:group_id]
    group = klass.find(group_id)

    size = group.entities.media.map do |e|
      e.medium.image_file_size || e.medium.document_file_size || 0.0
    end.sum
    human_size = size / 1024 / 1024
    puts "Please be aware that"
    puts "* the download will be composed with the rights of the 'admin' user"
    puts "* the download will be approximately #{human_size} MB in size"
    puts "* the process is running synchronously, blocking your terminal"
    puts "* the file is going to be cleaned up two weeks after it has been created"
    print "Continue [yes/no]? "
    response = STDIN.gets.strip

    if response == "yes"
      zip_file = Kor::ZipFile.new("#{Rails.root}/tmp/terminal_download.zip", 
        :user_id => User.admin.id,
        :file_name => "#{group.name}.zip"
      )

      group.entities.media.each do |e|
        zip_file.add_entity e
      end

      download = zip_file.create_as_download
      puts "Packaging complete, the zip file can be downloaded via"
      puts download.link
    end
  end

  def notify_expiring_users
    Kor.notify_expiring_users
  end

  def recheck_invalid_entities
    group = SystemGroup.find_by_name('invalids')
    valids = group.entities.select do |entity|
      entity.valid?
    end
    
    puts "removing #{valids.count} from the 'invalids' system group"
    group.remove_entities valids
  end

  def delete_expired_downloads
    Download.find(:all, :conditions => ['created_at < ?', 2.weeks.ago]).each do |download|
      download.destroy
    end
  end

  def editor_stats
    Kor::Statistics::Users.new(:verbose => true).run
  end

  def exif_stats
    require "exifr"
    Kor::Statistics::Exif.new(@config[:from], @config[:to], :verbose => true).run
  end

  def to_neo
    require "ruby-progressbar"
    graph = Kor::NeoGraph.new(User.admin)

    graph.reset!
    graph.import_all
  end

  def connect_random
    graph = Kor::NeoGraph.new(User.admin)
    graph.connect_random
  end

  def reset_guest_account
    Kor.ensure_guest_account!
  end

  def cleanup_sessions
    model = Class.new(ActiveRecord::Base)
    model.table_name = "sessions"
    model.where("created_at < ?", 5.days.ago).delete_all
  end

  def reset_admin_account
    puts "setting password of account 'admin' to 'admin' and granting all rights"
    Kor.ensure_admin_account!
  end

  def list_permissions
    puts "Entities: "
    data = [['entity (id)', 'collection (id)'] + Collection.policies]
    Entity.by_id(@config[:entity_id]).find_each do |entity|
      record = [
        "#{entity.name} (#{entity.id})",
        "#{entity.collection.name} (#{entity.collection.id})"
      ]

      Collection.policies.each do |policy|
        record << Kor::Auth.
          authorized_credentials(entity.collection, policy).
          map{|c| c.name}.
          join(', ')
      end

      data << record
    end
    print_table data

    puts "\nUsers: "
    data = [['username (id)', 'credentials']]
    User.by_id(@config[:user_id]).find_each do |user|
      data << ["#{user.name} (#{user.id})", user.groups.map{|c| c.name}.join(', ')]
    end
    print_table data
  end

  def cleanup_exception_logs
    ExceptionLog.delete_all
  end

  def secrets
    data = {}
    ['development', 'test', 'production'].each do |e|
      data[e] = {
        'secret_key_base' => Digest::SHA512.hexdigest("#{Time.now} #{rand}")
      }
    end

    File.open "#{Rails.root}/config/secrets.yml", 'w' do |f|
      f.write YAML.dump(data)
    end
  end

  def consistency_check
    Relationship.includes(:relation, :from, :to).inconsistent.each do |r|
      puts [
        "#{r.from.display_name} [#{r.from_id}, #{r.from.kind.name}]".colorize(:blue),
        r.relation.name.colorize(:light_blue),
        "#{r.to.display_name} [#{r.to_id}, #{r.to.kind.name}]".colorize(:blue),
        'is unexpected, the relation expects:',
        Kind.find(r.relation.from_kind_ids).map{|k| k.name}.join(','),
        '->',
        Kind.find(r.relation.to_kind_ids).map{|k| k.name}.join(',')
      ].join(' ')
    end
  end

  def import_erlangen_crm
    Kind.without_media.delete_all

    url = 'http://erlangen-crm.org/ontology/ecrm/ecrm_current.owl'
    response = HTTPClient.new.get(url)
    if response.status == 200
      doc = Nokogiri::XML(response.body)
      parent_map = {}
      doc.xpath('/rdf:RDF/owl:Class').each do |klass|
        kind = Kind.create(
          url: klass['rdf:about'],
          name: klass.xpath('rdfs:label').text,
          plural_name: klass.xpath('rdfs:label').text.gsub(/E\d+\s/, '').pluralize,
          description: (
            klass.xpath('rdfs:label').text + "\n\n" + 
            klass.xpath('rdfs:comment').text 
          ),
          abstract: true
        )

        unless kind.valid?
          p kind.errors.full_messages
          binding.pry
        end

        if parent = klass.xpath('rdfs:subClassOf/owl:Class').first
          parent_map[kind.url] = parent['rdf:about']
        end

        if parent = klass.xpath('rdfs:subClassOf[@rdf:resource]/@rdf:resource').first
          parent_map[kind.url] = parent.text
        end
      end

      parent_map.each do |child_url, parent_url|
        child = Kind.where(url: child_url).first
        parent = Kind.where(url: parent_url).first
        child.move_to_child_of(parent) if child && parent
      end
    else
      raise "request failed: GET #{url} (#{response.status} #{response.body})"
    end
  end


  protected

    def print_table(data)
      maxes = {}
      data.each do |record|
        row = []
        record.each_with_index do |field, i|
          maxes[i] ||= data.map{|r| r[i].to_s.size}.max
          row << "#{field.to_s.ljust(maxes[i])}"
        end
        puts '| ' + row.join(' | ') + ' |'
      end
    end

end