class Entity < ActiveRecord::Base

  # Settings
  
  serialize :attachment, JSON
  
  acts_as_taggable_on :tags
  acts_as_paranoid

  # Associations

  belongs_to :kind
  belongs_to :collection
  belongs_to :creator, :class_name => "User", :foreign_key => :creator_id
  belongs_to :updater, :class_name => "User", :foreign_key => :updater_id
 
  has_many :identifiers, :dependent => :destroy
  has_many :datings, :class_name => "EntityDating", :dependent => :destroy

  belongs_to :medium, :dependent => :destroy

  has_and_belongs_to_many :system_groups
  has_and_belongs_to_many :authority_groups
  has_and_belongs_to_many :user_groups

  has_many :out_rels, foreign_key: :from_id, class_name: 'Relationship', dependent: :destroy
  has_many :in_rels, foreign_key: :to_id, class_name: 'Relationship', dependent: :destroy

  has_many :outgoing_relationships, class_name: "DirectedRelationship", foreign_key: :from_id
  has_many :outgoing, through: :outgoing_relationships, source: :to

  has_many :incoming_relationships, class_name: "DirectedRelationship", foreign_key: :to_id
  has_many :incoming, through: :incoming_relationships, source: :from

  accepts_nested_attributes_for :medium, :datings, :allow_destroy => true

  validates_associated :datings

  validates :name, 
    :presence => {:if => :needs_name?},
    :uniqueness => {:scope => [:kind_id, :distinct_name], :allow_blank => true},
    :white_space => true
  validates :distinct_name,
    :uniqueness => {:scope => [ :kind_id, :name ], :allow_blank => true},
    :white_space => true
  validates :kind, :uuid, :collection_id, presence: true
  validates :no_name_statement, inclusion: {
    :allow_blank => true, :in => [ 'unknown', 'not_available', 'empty_name', 'enter_name' ]
  }

  validate(
    :validate_distinct_name_needed, :validate_dataset, :validate_properties,
    :attached_file
  )

  def attached_file
    if is_medium?
      if medium
        unless medium.document.file? || medium.image.file?
          medium.errors.add :document, :needs_file
          medium.errors.add :image, :needs_file
        end
      else
        errors.add :medium, :needs_medium
      end
    end
  end
  
  def validate_distinct_name_needed
    if has_name_duplicates?
      duplicate_collection = find_name_duplicates.first.collection
      
      if duplicate_collection.id != self.collection_id
        message = I18n.t('activerecord.errors.messages.needed_for_disambiguation', :collection => duplicate_collection.name)
        errors.add :distinct_name, message
      else
        errors.add :distinct_name
      end
    end
  end
  
  # TODO: still needed?
  def simple_errors
    result = []
    errors.each do |a, m|
      result << [I18n.t(a, :scope => [:activerecord, :attributes]), m] unless a == 'medium'
    end
    result
  end
  
  
  # Attachment

  def attachment
    unless self[:attachment]
      self[:attachment] = {}
    end

    self[:attachment]
  end

  def schema
    kind ? kind.field_instances(self) : []
  end

  def dataset
    attachment['fields'] ||= {}
  end

  def dataset=(value)
    attachment['fields'] = value
  end

  def fields
    kind.field_instances(self)
  end

  def field_hashes
    fields.map{|field| field.serializable_hash}
  end

  def synonyms
    (attachment['synonyms'].presence || []).uniq
  end

  def synonyms=(value)
    attachment['synonyms'] = case value
      when String then value.split("\n")
      when Array then value
      else
        raise "value '#{value.inspect} can't be assigned as synonyms"
    end
  end

  def properties
    attachment['properties'] ||= []
  end

  def properties=(value)
    attachment['properties'] = value
  end

  def validate_dataset
    schema.each do |field|
      field.validate_value
    end
  end

  def validate_properties
    properties.each do |property|
      errors.add :properties, :needs_label if property['label'].blank?
      errors.add :properties, :needs_value if property['value'].blank?
    end
  end


  # Callbacks
  
  before_validation :generate_uuid, :sanitize_distinct_name
  before_save :generate_uuid, :add_to_user_group
  after_commit :update_elastic, :update_identifiers
  
  def sanitize_distinct_name
    self.distinct_name = nil if self.distinct_name == ""
  end
  
  def generate_uuid
    self.uuid ||= SecureRandom.uuid
  end
  
  def update_elastic
    unless is_medium?
      if deleted?
        Kor::Elastic.drop self
      else
        Kor::Elastic.index self, :full => true
      end
    end
  end

  def update_identifiers
    if self.deleted?
      self.identifiers.destroy_all
    else
      kind.fields.identifiers.each do |field|
        field.entity = self
        if field.value.present?
          id = identifiers.find_or_create_by(kind: field.name)
          id.update_attributes :value => field.value
        else
          id = identifiers.where(:kind =>  field.name).first
          id.destroy if id
        end
      end
    end
  end

  def after_merge
    update_elastic
    update_identifiers
  end

  # Attributes
  
  def recent?
    @recent
  end
  
  def remember_recent!
    @recent = true
  end
  
  
  # ---------------------------------------------------------- miscellaneous ---
  attr_accessor :user_group_id
  def add_to_user_group
    if user_group_id
      user_group = UserGroup.find(user_group_id)
      self.user_group_id = nil
      user_group.add_entities self
    end
  end
  
  def mark_invalid
    SystemGroup.find_or_create_by(:name => 'invalid').add_entities self
  end

  def mark_valid
    SystemGroup.find_or_create_by(:name => 'invalid').remove_entities self
  end
  
  
  ############################ user related ####################################

  def last_updated_by
    updater || creator
  end
  
  scope :allowed, lambda { |user, policy|
    collections = Kor::Auth.authorized_collections(user, policy)
    where("entities.collection_id IN (?)", collections.map{|c| c.id})
  }
  

  ############################ comment related #################################

  def html_comment
    red_cloth = RedCloth.new(self.comment || "")
    red_cloth.sanitize_html = true
    red_cloth.to_html
  end
  
  
  ############################ relationships ###################################
  
  def degree
    Relationship.where("from_id = ? OR to_id = ?", self.id, self.id).count
  end

  def primary_entities(user)
    relation_names = Relation.primary_relation_names
    outgoing.
      allowed(user, :view).
      where('directed_relationships.relation_name' => relation_names).
      without_media
  end

  def secondary_entities(user)
    relation_names = Relation.secondary_relation_names
    outgoing.
      allowed(user, :view).
      where('directed_relationships.relation_name' => relation_names).
      without_media
  end
  
  def relation_counts(user, options = {})
    options.reverse_merge! media: false
    media_id = Kind.medium_kind.id

    scope = outgoing_relationships.
      allowed(user, :view).
      includes(:to).
      group('directed_relationships.relation_name')

    if options[:media]
      scope = scope.where('tos.kind_id = ?', media_id)
    else
      scope = scope.where('tos.kind_id != ?', media_id)
    end

    scope.count
  end

  def media_count(user)
    outgoing_relationships
      .with_to
      .where('tos.kind_id = ?', Kind.medium_kind_id)
      .count
  end

  def media(user)
    @media ||= outgoing_relationships.
      by_to_kind(Kind.medium_kind.id).
      allowed(user).
      map{|dr| dr.to}
  end

  
  ############################ naming ##########################################
  
  def medium_hash
    self.medium ? self.medium.datahash : nil
  end
  
  def kind_name(options = {})
    options.reverse_merge!(:include_subtype => true)
    
    result = is_medium? ? medium.content_type : kind.name
    if options[:include_subtype] && !self[:subtype].blank?
       result += " (#{self[:subtype]})"
    end
    result
  end
  
  def has_name_duplicates?
    find_name_duplicates.count > 0
  end
  
  def find_name_duplicates
    if is_medium?
      []
    else
      result = self.class.where(:name => name, :distinct_name => distinct_name, :kind_id => kind_id)
      new_record? ? result : result.where("id != ?", id)
    end
  end

  def needs_name?
    !is_medium? && no_name_statement == 'enter_name'
  end

  def has_distinct_name?
    distinct_name.blank? ? false : true
  end

  def display_name
    if is_medium?
      "#{Medium.model_name.human} #{id}"
    elsif no_name_statement == 'enter_name'
      distinct_name.blank? ? name : "#{name} (#{distinct_name})".strip
    else
      I18n.t('values.no_name_statements.' + no_name_statement).capitalize_first_letter
    end
  end

  def no_name_statement
    read_attribute(:no_name_statement) || 'enter_name'
  end
  
  
  ############################ kind related ####################################

  def is_medium?
    !!self[:medium_id] ||
    !!self.medium ||
    !!Kind.medium_kind && (
      (self.kind_id == Kind.medium_kind_id) ||
      (self.kind == Kind.medium_kind)
    )
  end


  ############################ dating ##########################################

  # TODO: can this method be removed?
  def new_datings_attributes=(values)
    values.each do |v|
      datings.build v
    end
  end

  # TODO: can this method be removed?
  def existing_datings_attributes=(values)
    datings.reject(&:new_record?).each do |d|
      attributes = values[d.id.to_s]
      if attributes
        d.attributes = attributes
      else
        datings.delete(d)
      end
    end
  end

  # ----------------------------------------------------------------- search ---
  def self.filtered_tag_counts(term, options = {})
    options.reverse_merge!(:limit => 10)
    
    Entity.
      tag_counts(:order => 'count DESC', :limit => options[:limit]).
      where('tags.name LIKE ?', "%#{term}%")
  end
  
  scope :by_ordered_id_array, lambda { |*ids|
    if ids.present? && ids.flatten.compact.present?
      ids = ids.flatten.compact
      where(id: ids).order("FIELD(id,#{ids.join(',')})")
    else
      none
    end
  }
  scope :by_relation_name, lambda {|relation_name|
    if relation_name
      kind_ids = Relation.where(name: relation_name).map{|r| r.to_kind_ids}
      kind_ids << Relation.where(reverse_name: relation_name).map{|r| r.from_kind_ids}
      where(kind_id: kind_ids.flatten)
    else
      all
    end
  }  
  scope :by_id, lambda {|id| id.present? ? where(id: id) : all}
  scope :updated_after, lambda {|time| time.present? ? where("updated_at >= ?", time) : all}
  scope :updated_before, lambda {|time| time.present? ? where("updated_at <= ?", time) : all}
  scope :only_kinds, lambda {|ids| ids.present? ? where("entities.kind_id IN (?)", ids) : all }
  scope :alphabetically, lambda { order("name asc, distinct_name asc") }
  scope :newest_first, lambda { order("created_at DESC") }
  scope :recently_updated, lambda {|*args| where("updated_at > ?", (args.first || 2.weeks).ago) }
  scope :latest, lambda {|*args| where("created_at > ?", (args.first || 2.weeks).ago) }
  scope :within_collections, lambda {|ids| ids.present? ? where("entities.collection_id IN (?)", ids) : all }
  scope :media, lambda { only_kinds(Kind.medium_kind.id) }
  scope :without_media, lambda { 
    if media = Kind.medium_kind
      where("entities.kind_id != ?", media.id)
    else
      all
    end
  }
  # TODO the scopes are not combinable e.g. id-conditions overwrite each other
  # TODO: rewrite this not to collect singular entity ids
  scope :named_like, lambda { |user, pattern|
    if pattern.blank?
      all
    else
      pattern_query = pattern.tokenize.map{ |token| "entities.name LIKE ?"}.join(" AND ")
      pattern_values = pattern.tokenize.map{ |token| "%" + token + "%" }

      entity_ids = Kor::Elastic.new(user).search(:synonyms => pattern, :size => Entity.count).ids
      entity_ids += Entity.where([pattern_query.gsub('name','distinct_name')] + pattern_values ).collect{|e| e.id}

      id_query = entity_ids.blank? ? "" : "OR entities.id IN (?)"
      entity_id_bind_variables = entity_ids.blank? ? [] : [ entity_ids ]

      query = ["(#{pattern_query}) #{id_query}"] + pattern_values + entity_id_bind_variables
      where(query)
    end
  }
  scope :has_property, lambda { |user, properties|
    if properties.blank?
      all
    else
      ids = Kor::Elastic.new(user).search(
        :properties => properties,
        :size => Entity.count,
      ).ids
      where("entities.id IN (?)", ids.uniq)
    end
  }
  scope :related_to, lambda { |user, spec|
    entity_ids = nil
    spec ||= []

    relation_names = spec.map{|s| s["relation_name"]}.select{|e| e.present?}
    entity_names = spec.map{|s| s["entity_name"]}.select{|e| e.present?}

    scope = all
    if relation_names.present?
      scope = scope.joins(:outgoing).where(
        'directed_relationships.relation_name' => relation_names
      )
    end
    if entity_names.present?
      query = entity_names.map{|n| 'outgoings_entities.name LIKE ?'}
      query = "(#{query.join ') OR ('})"
      names = entity_names.map{|n| "%#{n}%" }
      scope = scope.joins(:outgoing).where(query, names)
    end

    scope
  }
  scope :dated_in, lambda {|dating|
    if dating.present?
      if parsed = EntityDating.parse(dating)
        joins(:datings).
        where("entity_datings.to_day > ?", EntityDating.julian_date_for(parsed[:from])).
        where("entity_datings.from_day < ?", EntityDating.julian_date_for(parsed[:to]))
      else
        none
      end
    else
      all
    end
  }
  scope :dataset_attributes, lambda { |user, dataset|
    dataset ||= {}
    ids = Kor::Elastic.new(user).search(
      :dataset => dataset,
      :size => Entity.count
    ).ids

    dataset.values.all?{|v| v.blank?} ? all : where("entities.id IN (?)", ids.uniq)
  }
  scope :load_fully, lambda { joins(:kind, :collection).includes(:medium) }
  scope :isolated, lambda {
    joins("LEFT JOIN relationships fromrels ON entities.id = fromrels.from_id").
    joins("LEFT JOIN relationships torels ON entities.id = torels.to_id").
    where("fromrels.id is NULL AND torels.id IS NULL")
  }
  scope :pageit, lambda { |page, per_page|
    page = [(page || 1).to_i, 1].max
    per_page = [(per_page || 20).to_i, Kor.config['app']['max_results_per_request']].min

    offset((page - 1) * per_page).limit(per_page)
  }
  
end
