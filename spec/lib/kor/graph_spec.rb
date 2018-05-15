require 'rails_helper'

RSpec.describe Kor::Graph do

  it 'should fail without a vaild user' do
    expect{described_class.new(user: Object.new)}.to raise_error(Kor::Exception)
    expect{described_class.new(user: nil)}.to raise_error(Kor::Exception)
    expect{described_class.new}.to raise_error(Kor::Exception)
  end

  it 'should obey permissions' do
    jdoe = User.find_by(name: 'jdoe')
    graph = described_class.new(user: jdoe)
    expect(graph.search.total).to eq(2)

    graph = described_class.new(user: User.admin)
    expect(graph.search.total).to eq(3)
  end

  it 'should search by id' do
    mona_lisa = Entity.find_by(name: 'Mona Lisa')
    graph = described_class.new(user: User.admin)

    results = graph.search(id: mona_lisa.id)
    expect(results.total).to eq(1)
    expect(results.records.first).to eq(mona_lisa)
  end

  it 'should search by uuid' do
    mona_lisa = Entity.find_by(name: 'Mona Lisa')
    graph = described_class.new(user: User.admin)

    results = graph.search(uuid: '12345-56789-563454-3123')
    expect(results.total).to eq(0)

    results = graph.search(uuid: mona_lisa.uuid)
    expect(results.total).to eq(1)
    expect(results.records.first).to eq(mona_lisa)
  end

  it 'should search by name' do
    mona_lisa = Entity.find_by(name: 'Mona Lisa')
    graph = described_class.new(user: User.admin)

    results = graph.search(name: 'Monalisa')
    expect(results.total).to eq(0)

    results = graph.search(name: 'Mona Lisa')
    expect(results.total).to eq(1)
    expect(results.records.first).to eq(mona_lisa)
  end

  it 'should search by subtype' do
    mona_lisa = Entity.find_by(name: 'Mona Lisa')
    graph = described_class.new(user: User.admin)

    results = graph.search(subtype: 'painting')
    expect(results.total).to eq(0)

    results = graph.search(subtype: 'portrait')
    expect(results.total).to eq(1)
    expect(results.records.first).to eq(mona_lisa)
  end

  it 'should search by comment' do
    mona_lisa = Entity.find_by(name: 'Mona Lisa')
    graph = described_class.new(user: User.admin)

    results = graph.search(comment: 'beautiful')
    expect(results.total).to eq(0)

    results = graph.search(comment: 'popular')
    expect(results.total).to eq(1)
    expect(results.records.first).to eq(mona_lisa)
  end

  it 'should search by term' do
    graph = described_class.new(user: User.admin)

    expect {
      graph.search(term: 'portrait')
    }.to raise_error(Kor::Exception, 'searching by any of [:term, :property, :dataset, :synonym] is only available with elasticsearch')
  end

  it 'should search by dating' do
    leonardo = Entity.find_by(name: 'Mona Lisa')
    graph = described_class.new(user: User.admin)

    results = graph.search(dating: '1344')
    expect(results.total).to eq(0)

    results = graph.search(dating: '1499')
    expect(results.total).to eq(1)
    expect(results.records.first).to eq(leonardo)
  end

  it 'should search by property'
  it 'should search by dataset value(s)'
  it 'should search by relation name'
  it 'should search by related entity name'
  it 'should search by relation name and related entity name'
  it 'should not search via non-allowed related entities'

  # context 'postponded after v2.0.0' do
  #   before :each do
  #     skip "postponed after v2.0.0"

  #     default = FactoryGirl.create :default
  #     admins = FactoryGirl.create :admins
  #     Grant.create :collection => default, :credential => admins, :policy => :view
  #     FactoryGirl.create :admin, :groups => [admins]
  #   end

  #   it "should not find paths of length 0" do
  #     graph = described_class.new(:user => User.admin)
  #     expect(graph.find_paths([])).to eq([])

  #     FactoryGirl.create :has_created
  #     mona_lisa = FactoryGirl.create :mona_lisa
  #     leonardo = FactoryGirl.create :leonardo
  #     Relationship.relate_and_save leonardo, "has created", mona_lisa 

  #     expect(graph.find_paths([])).to eq([])
  #   end

  #   it "should not find incomplete paths" do
  #     graph = described_class.new(:user => User.admin)
  #     expect(graph.find_paths([{}, {}])).to eq([])

  #     FactoryGirl.create :has_created
  #     mona_lisa = FactoryGirl.create :mona_lisa
  #     leonardo = FactoryGirl.create :leonardo
  #     Relationship.relate_and_save leonardo, "has created", mona_lisa 

  #     expect(graph.find_paths([{}, {}])).to eq([])
  #   end

  #   it "should find paths of length 1" do
  #     graph = described_class.new(:user => User.admin)
  #     expect(graph.find_paths([{}, {}, {}])).to eq([])

  #     has_created = FactoryGirl.create :has_created
  #     mona_lisa = FactoryGirl.create :mona_lisa
  #     leonardo = FactoryGirl.create :leonardo
  #     the_last_supper = FactoryGirl.create :the_last_supper
  #     Relationship.relate_and_save leonardo, "has created", mona_lisa
  #     Relationship.relate_and_save leonardo, "has created", the_last_supper 

  #     results = graph.find_paths([{}, {}, {}])
  #     expect(results.size).to eq(4)

  #     expect(results[0][0]).to include('id' => leonardo.id)
  #     expect(results[0][1]).to include(
  #       'relation_id' => has_created.id
  #     )
  #     expect(results[0][2]).to include('id' => mona_lisa.id)

  #     expect(results[1][0]).to include('id' => leonardo.id)
  #     expect(results[1][1]).to include(
  #       'relation_id' => has_created.id
  #     )
  #     expect(results[1][2]).to include('id' => the_last_supper.id)

  #     expect(results[2][0]).to include('id' => mona_lisa.id)
  #     expect(results[2][1]).to include(
  #       'relation_id' => has_created.id
  #     )
  #     expect(results[2][2]).to include('id' => leonardo.id)

  #     expect(results[3][0]).to include('id' => the_last_supper.id)
  #     expect(results[3][1]).to include(
  #       'relation_id' => has_created.id
  #     )
  #     expect(results[3][2]).to include('id' => leonardo.id)
  #   end

  #   it "should find paths of length 2" do
  #     has_created = FactoryGirl.create :has_created
  #     has_created = FactoryGirl.create :is_located_at
  #     mona_lisa = FactoryGirl.create :mona_lisa
  #     leonardo = FactoryGirl.create :leonardo
  #     paris = FactoryGirl.create :paris
  #     Relationship.relate_and_save leonardo, "has created", mona_lisa
  #     Relationship.relate_and_save mona_lisa, "is located at", paris

  #     graph = described_class.new(:user => User.admin)
  #     results = graph.find_paths([{}, {}, {}, {}, {}])

  #     expect(results.size).to eq(2)
  #   end

  #   it "should find paths of length 2 in a diamond shaped graph" do
  #     has_created = FactoryGirl.create :has_created
  #     has_created = FactoryGirl.create :is_located_at
  #     mona_lisa = FactoryGirl.create :mona_lisa
  #     leonardo = FactoryGirl.create :leonardo
  #     the_last_supper = FactoryGirl.create :the_last_supper
  #     paris = FactoryGirl.create :paris
  #     Relationship.relate_and_save leonardo, "has created", mona_lisa
  #     Relationship.relate_and_save leonardo, "has created", the_last_supper 
  #     Relationship.relate_and_save mona_lisa, "is located at", paris
  #     Relationship.relate_and_save the_last_supper, "is located at", paris

  #     graph = described_class.new(:user => User.admin)
  #     results = graph.find_paths([{}, {}, {}, {}, {}])
  #     expect(results.size).to eq(8)
  #   end

  #   it "should find paths of length 2 with kind constraints" do
  #     has_created = FactoryGirl.create :has_created
  #     has_created = FactoryGirl.create :is_located_at
  #     mona_lisa = FactoryGirl.create :mona_lisa
  #     leonardo = FactoryGirl.create :leonardo
  #     the_last_supper = FactoryGirl.create :the_last_supper
  #     paris = FactoryGirl.create :paris
  #     Relationship.relate_and_save leonardo, "has created", mona_lisa
  #     Relationship.relate_and_save leonardo, "has created", the_last_supper 
  #     Relationship.relate_and_save mona_lisa, "is located at", paris
  #     Relationship.relate_and_save the_last_supper, "is located at", paris

  #     graph = described_class.new(:user => User.admin)
  #     results = graph.find_paths([{'kind_id' => leonardo.kind_id}, {}, {}, {}, {}])
  #     expect(results.size).to eq(2)

  #     results = graph.find_paths([{'kind_id' => leonardo.kind_id.to_s}, {}, {}, {}, {}])
  #     expect(results.size).to eq(2)

  #     results = graph.find_paths([{'kind_id' => leonardo.kind_id}, {}, {}, {}, {'kind_id' => paris.kind_id}])
  #     expect(results.size).to eq(2)

  #     results = graph.find_paths([{'kind_id' => leonardo.kind_id}, {}, {}, {}, {'kind_id' => leonardo.kind_id}])
  #     expect(results.size).to eq(0)
  #   end

  #   it "should find paths of length 2 with permission constraints" do
  #     default = Collection.where(:name => "default").first
  #     admins = Credential.where(:name => "admins").first

  #     priv = FactoryGirl.create :private
  #     students = FactoryGirl.create :students
  #     jdoe = FactoryGirl.create :jdoe, :groups => [students]
   
  #     Grant.create :collection => default, :credential => admins, :policy => :view
  #     Grant.create :collection => default, :credential => students, :policy => :view
  #     Grant.create :collection => priv, :credential => admins, :policy => :view

  #     has_created = FactoryGirl.create :has_created
  #     has_created = FactoryGirl.create :is_located_at
  #     mona_lisa = FactoryGirl.create :mona_lisa
  #     leonardo = FactoryGirl.create :leonardo
  #     the_last_supper = FactoryGirl.create :the_last_supper
  #     paris = FactoryGirl.create :paris
  #     Relationship.relate_and_save leonardo, "has created", mona_lisa
  #     Relationship.relate_and_save leonardo, "has created", the_last_supper 
  #     Relationship.relate_and_save mona_lisa, "is located at", paris
  #     Relationship.relate_and_save the_last_supper, "is located at", paris

  #     graph = described_class.new(:user => jdoe)
  #     results = graph.find_paths([{'kind_id' => leonardo.kind_id}, {}, {}, {}, {}])
  #     expect(results.size).to eq(2)

  #     the_last_supper.update_attributes :collection => priv

  #     results = graph.find_paths([{'kind_id' => leonardo.kind_id}, {}, {}, {}, {}])
  #     expect(results.size).to eq(1)
  #   end

  #   it "should find paths of length 2 with relation constraints" do
  #     has_created = FactoryGirl.create :has_created
  #     has_created = FactoryGirl.create :is_located_at
  #     mona_lisa = FactoryGirl.create :mona_lisa
  #     leonardo = FactoryGirl.create :leonardo
  #     the_last_supper = FactoryGirl.create :the_last_supper
  #     paris = FactoryGirl.create :paris
  #     Relationship.relate_and_save leonardo, "has created", mona_lisa
  #     Relationship.relate_and_save leonardo, "has created", the_last_supper 
  #     Relationship.relate_and_save mona_lisa, "is located at", paris
  #     Relationship.relate_and_save the_last_supper, "is located at", paris

  #     graph = described_class.new(:user => User.admin)
  #     results = graph.find_paths([{}, {'name' => 'has created'}, {}, {'name' => 'is located at'}, {}])
  #     expect(results.size).to eq(2)
  #   end

  #   it "should find paths of length 2 with entity and relation constraints" do
  #     media = FactoryGirl.create :media
  #     shows = FactoryGirl.create :shows
  #     has_created = FactoryGirl.create :has_created
  #     mona_lisa = FactoryGirl.create :mona_lisa
  #     mona_lisa_pic = FactoryGirl.create :picture_a
  #     the_last_supper = FactoryGirl.create :the_last_supper
  #     the_last_supper_pic = FactoryGirl.create :picture_b
  #     leonardo = FactoryGirl.create :leonardo

  #     Relationship.relate_and_save leonardo, "has created", mona_lisa
  #     Relationship.relate_and_save leonardo, "has created", the_last_supper 
  #     Relationship.relate_and_save mona_lisa_pic, "shows", mona_lisa
  #     Relationship.relate_and_save the_last_supper_pic, "shows", the_last_supper

  #     graph = described_class.new(:user => User.admin)
  #     results = graph.find_paths([
  #       {'id' => mona_lisa_pic.id},
  #       {'name' => 'shows'}, {}, 
  #       {'name' => 'has been created by'}, {}
  #     ])
  #     expect(results.size).to eq(1)
  #     expect(results[0][0]['id']).to eq(mona_lisa_pic.id)
  #     expect(results[0][1]['relation_id']).to eq(shows.id)
  #     expect(results[0][1]['reverse']).to be_falsey
  #     expect(results[0][2]['id']).to eq(mona_lisa.id)
  #     expect(results[0][3]['relation_id']).to eq(has_created.id)
  #     expect(results[0][3]['reverse']).to be_truthy
  #     expect(results[0][4]['id']).to eq(leonardo.id)
  #   end

  #   it "should limit the amount of records returned by the path api"
  # end

end