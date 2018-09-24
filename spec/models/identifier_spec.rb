require "rails_helper"

RSpec.describe Identifier do

  it "should require a type and a value" do
    id = described_class.new
    expect(id.valid?).to be_falsey
    expect(id.errors.full_messages.size).to eq(2)
  end

  it "should not allow duplicate identifiers per kind" do
    mona_lisa = FactoryGirl.create :mona_lisa

    described_class.create(
      :entity => mona_lisa, 
      :kind => "ulan",
      :value => "123"
    )

    id = described_class.new(
      :entity => mona_lisa, 
      :kind => "ulan",
      :value => "456"
    )

    expect(id.valid?).to be_falsey
    expect(id.errors.full_messages.size).to eq(1)
  end

  it "should be created when an identifier-field has a value" do
    people = FactoryGirl.create :people, :fields => [
      Field.new(:name => "gnd_id", :is_identifier => true, :show_label => "GND-ID")
    ]
    leonardo = FactoryGirl.create :leonardo, :dataset => {"gnd_id" => "1234"}

    expect(described_class.count).to eq(1)

    id = described_class.first
    expect(id.entity_id).to eq(leonardo.id)
    expect(id.kind).to eq("gnd_id")
    expect(id.value).to eq("1234")
  end

  it "should be removed when an identifier-field is blank" do
    people = FactoryGirl.create :people, :fields => [
      Field.new(:name => "gnd_id", :is_identifier => true, :show_label => "GND-ID")
    ]
    leonardo = FactoryGirl.create :leonardo, :dataset => {"gnd_id" => "1234"}
    leonardo.update_attributes :dataset => {"gnd_id" => ""}

    expect(described_class.count).to eq(0)
  end

  it "should be removed when a field is not an identifier anymore" do
    Delayed::Worker.delay_jobs = false

    people = FactoryGirl.create :people, :fields => [
      Field.new(:name => "gnd_id", :is_identifier => true, :show_label => "GND-ID")
    ]
    leonardo = FactoryGirl.create :leonardo, :dataset => {"gnd_id" => "1234"}
    people.fields.first.update_attributes :is_identifier => false

    expect(described_class.count).to eq(0)
  end

  it "should be created when a field becomes an identifier" do
    Delayed::Worker.delay_jobs = false

    people = FactoryGirl.create :people, fields: [
      Field.new(:name => "gnd_id", :show_label => "GND-ID")
    ]
    leonardo = FactoryGirl.create :leonardo, :dataset => {"gnd_id" => "1234"}
    expect(described_class.count).to eq(0)

    people.fields.first.update_attributes is_identifier: true
    
    expect(described_class.count).to eq(1)
  end

  it "should be removed when with the entity" do
    people = FactoryGirl.create :people, :fields => [
      Field.new(:name => "gnd_id", :is_identifier => true, :show_label => "GND-ID")
    ]
    leonardo = FactoryGirl.create :leonardo, :dataset => {"gnd_id" => "1234"}

    expect(described_class.count).to eq(1)

    leonardo.destroy
    expect(described_class.count).to eq(0)
  end

  it "should be removed when the field is removed" do
    people = FactoryGirl.create :people, :fields => [
      Field.new(:name => "gnd_id", :is_identifier => true, :show_label => "GND-ID")
    ]
    leonardo = FactoryGirl.create :leonardo, :dataset => {"gnd_id" => "1234"}

    people.fields.first.destroy

    expect(described_class.count).to eq(0)
  end

  it "should not be removed when the field is removed but there are other identifier fields with the same name" do
    people = FactoryGirl.create :people, :fields => [
      Field.new(:name => "gnd_id", :is_identifier => true, :show_label => "GND-ID")
    ]
    leonardo = FactoryGirl.create :leonardo, :dataset => {"gnd_id" => "1234"}
    works = FactoryGirl.create :locations, :fields => [
      Field.new(:name => "gnd_id", :is_identifier => true, :show_label => "GND-ID")
    ]

    people.fields.first.destroy

    expect(described_class.count).to eq(1)
  end

  it "should only iterate entities on update or if other fields were changed" do
    Delayed::Worker.delay_jobs = false

    expect_any_instance_of(Field).not_to receive(:create_identifiers)
    people = FactoryGirl.create :people
    people.fields.create(:name => "gnd_id", :is_identifier => true, :show_label => "GND-ID")
  end

end