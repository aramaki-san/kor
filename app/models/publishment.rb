class Publishment < ActiveRecord::Base
  belongs_to :user_group, required: true
  belongs_to :user, required: true

  validates :name, presence: true

  after_validation(:on => :create) do |model|
    model.generate_uuid
    model.set_expiry
  end

  def user_group_name
    user_group.name
  end

  def generate_uuid
    self.uuid = SecureRandom.uuid.delete("-")[0..11]
  end

  def set_expiry
    self.valid_until = Kor.publishment_expiry_time unless self.valid_until
  end

  scope :owned_by, lambda { |user| where(:user_id => user.id) }
end
