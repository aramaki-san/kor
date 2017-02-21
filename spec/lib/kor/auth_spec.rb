require "rails_helper"

describe Kor::Auth do

  before :each do
    FactoryGirl.create :ldap_template
  end

  it "should create users when they don't exist" do
    expect(User).to receive(:generate_password).exactly(:once)
    user = described_class.authorize "jdoe", "email" => "jdoe@coneda.net"

    expect(user.name).to eq("jdoe")
  end

  it "should call external auth scripts" do
    FactoryGirl.create :user, :name => "example_auth", :email => 'ea@example.com'

    expect(described_class.login "jdoe", "wrong").to be_falsey
    expect(described_class.login "jdoe", "123456").to be_truthy

    expect(User.count).to eq(3)
    expect(User.last.parent_username).to eq("ldap")
  end

  it "should escape double quotes in username and password" do
    expect(described_class.login "\" echo 'bla' #", "123456").to be_falsey
  end

  it "should pass passwords with special characters to external auth scripts" do
    user = described_class.login "cangoin", "$0.\/@#"
    expect(user.name).to eq("cangoin")
  end

  it "should pass usernames with special characters to external auth scripts" do
    user = described_class.login "can.go.in", "$0.\/@#"
    expect(user.name).to eq("can.go.in")
  end

  it "should pass username and password directly via env vars" do
    user = described_class.login "jdoe", '234567'
    expect(user.name).to eq("jdoe")
  end

  it "should default the source type to 'script'" do
    sources = Kor.config['auth.sources']

    expect(described_class.script_sources.size).to eq(2)
    expect(described_class.script_sources.keys).to eq([
      'credentials_via_file', 'credentials_via_env'
    ])
  end

  context 'prefers the mail attribute to the domain attribute' do

    it 'has mail attribute in config and finds a value for it' do
      env = {'REMOTE_USER' => 'jdoe', 'mail' => 'jdoe@personal.com'}
      expect(described_class).to receive(:authorize).with(
        'jdoe', hash_including(email: 'jdoe@personal.com')
      )
      expect(described_class.env_login env)
    end

    it 'has mail attribute in config and finds no value for it' do
      env = {'REMOTE_USER' => 'jdoe'}
      expect(described_class).to receive(:authorize).with(
        'jdoe', hash_including(:email => 'jdoe@example.com')
      )
      expect(described_class.env_login env)
    end

    it 'has no mail attribute in config and finds a value for it' do
      allow(described_class).to receive(:config) do
        result = Kor.config['auth']
        result['sources']['remote_user'].delete 'mail'
        result
      end

      env = {'REMOTE_USER' => 'jdoe', 'mail' => 'jdoe@personal.com'}
      expect(described_class).to receive(:authorize).with(
        'jdoe', hash_including(:email => 'jdoe@example.com')
      )
      expect(described_class.env_login env)
    end

    it 'has no mail attribute in config and finds no value for it' do
      allow(described_class).to receive(:config) do
        result = Kor.config['auth']
        result['sources']['remote_user'].delete 'mail'
        result
      end

      env = {'REMOTE_USER' => 'jdoe'}
      expect(described_class).to receive(:authorize).with(
        'jdoe', hash_including(:email => 'jdoe@example.com')
      )
      expect(described_class.env_login env)
    end

  end

  context "authorization" do

    include DataHelper

    before :each do
      test_data_for_auth
      test_kinds
    end

    def side_collection
      @side_collection ||= FactoryGirl.create :private
    end
    
    def side_entity(attributes = {})
      @side_entity ||= FactoryGirl.create :leonardo, :collection => side_collection
    end
    
    def main_entity(attributes = {})
      @main_entity ||= FactoryGirl.create :mona_lisa
    end
    
    def set_side_collection_policies(policies = {})
      policies.each do |p, c|
        Kor::Auth.grant side_collection, p, :to => c
      end
    end
    
    def set_main_collection_policies(policies = {})
      policies.each do |p, c|
        Kor::Auth.grant @main, p, :to => c
      end
    end
    
    it "should say if a user has more than one right" do
      expect(Kor::Auth.allowed_to?(@admin, :view, @main)).to be_truthy
      expect(Kor::Auth.allowed_to?(@admin, [:view, :edit], @main)).to be_truthy
      expect(Kor::Auth.allowed_to?(@admin, [:view, :edit, :approve], @main)).to be_truthy
    end
    
    it "should give all authorized collections for a user and a set of policies" do
      expect(Kor::Auth.authorized_collections(@admin, :view)).to eql([@main])
      expect(Kor::Auth.authorized_collections(@admin, [:view, :edit])).to eql([@main])
      expect(Kor::Auth.authorized_collections(@admin, [:view, :edit, :approve])).to eql([@main])
    end

    it "should allow to inherit permissions from another user" do
      hmustermann = FactoryGirl.create :hmustermann
      jdoe = FactoryGirl.create :jdoe
      students = FactoryGirl.create :students
      jdoe.groups << students
      hmustermann.parent = jdoe

      expect(described_class.groups(hmustermann)).to include(students)
    end

    it "should not allow deleting entities without appropriate authorization" do
      set_side_collection_policies :view => [@admins]

      result = described_class.allowed_to?(User.admin, :delete, side_entity.collection)
      expect(result).to be_falsey
    end

    it "should not show unauthorized entities" do
      result = described_class.allowed_to?(User.admin, :view, side_entity.collection)
      expect(result).to be_falsey
    end

    it "should allow to show authorized entities" do
      set_side_collection_policies :view => [@admins]
      result = described_class.allowed_to?(User.admin, :view, side_entity.collection)
      expect(result).to be_truthy
    end

  end

end