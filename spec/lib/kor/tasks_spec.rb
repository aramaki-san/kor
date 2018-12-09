require 'rails_helper'

RSpec.describe Kor::Tasks do
  before :each do
    @out = []
    allow(Kor::Tasks).to receive(:puts){|l| @out << l}
  end

  it 'should run reprocess_all' do
    Kor::Tasks.reprocess_all
    expect(@out.first).to eq('Found 2 media entities')
  end

  it 'should run index_all', elastic: true do
    Kor::Elastic.drop_index
    expect(Kor::Search.new(admin).total).to eq(0)

    Kor::Tasks.index_all
    expect(Kor::Search.new(admin).total).to eq(7)
  end

  it 'should run group_to_zip' do
    Kor::Tasks.group_to_zip(
      class_name: 'UserGroup',
      group_id: nice.id,
      assume_yes: true
    )
    download = Download.last
    expect(@out.last).to eq("http://localhost:47001/downloads/#{download.uuid}")
  end

  it 'should import the erlangen CRM' do
    Kor::Tasks.import_erlangen_crm

    people = Kind.find_by!(name: 'E21 Person')
    expect(people.name).to eq('E21 Person')
  end
end