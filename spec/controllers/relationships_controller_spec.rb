require 'rails_helper'

RSpec.describe RelationshipsController, type: :controller do
  render_views

  it 'should not POST create' do
    last_supper = Entity.find_by! name: 'The Last Supper'
    paris = Entity.find_by! name: 'Paris'
    params = {
      from_id: last_supper.id,
      relation_name: 'is related to',
      to_id: paris.id
    }
    post 'create', params: {relationship: params}
    expect(response).to be_forbidden
  end

  it 'should not PATCH update' do
    mona_lisa = Entity.find_by! name: 'Mona Lisa'
    last_supper = Entity.find_by! name: 'The Last Supper'
    relationship = Relationship.find_by!(from_id: mona_lisa.id, to_id: last_supper.id)
    patch 'update', params: {
      id: relationship.id,
      relationship: {properties: ['perhaps']}
    }
    expect(response).to be_forbidden
  end

  it 'should not DELETE destroy' do
    mona_lisa = Entity.find_by! name: 'Mona Lisa'
    last_supper = Entity.find_by! name: 'The Last Supper'
    relationship = Relationship.find_by!(from_id: mona_lisa.id, to_id: last_supper.id)
    delete 'destroy', params: {id: relationship.id}
    expect(response).to be_forbidden
  end

  context 'as jdoe' do
    before :each do
      current_user User.find_by!(name: 'jdoe')
    end

    it 'should not POST create' do
      last_supper = Entity.find_by! name: 'The Last Supper'
      paris = Entity.find_by! name: 'Paris'
      params = {
        from_id: last_supper.id,
        relation_name: 'is related to',
        to_id: paris.id
      }
      post 'create', params: {relationship: params}
      expect(response).to be_forbidden
    end

    it 'should not PATCH update' do
      mona_lisa = Entity.find_by! name: 'Mona Lisa'
      last_supper = Entity.find_by! name: 'The Last Supper'
      relationship = Relationship.find_by!(from_id: mona_lisa.id, to_id: last_supper.id)
      patch 'update', params: {
        id: relationship.id,
        relationship: {properties: ['perhaps']}
      }
      expect(response).to be_forbidden
    end

    it 'should not DELETE destroy' do
      mona_lisa = Entity.find_by! name: 'Mona Lisa'
      last_supper = Entity.find_by! name: 'The Last Supper'
      relationship = Relationship.find_by!(from_id: mona_lisa.id, to_id: last_supper.id)
      delete 'destroy', params: {id: relationship.id}
      expect(response).to be_forbidden
    end
  end

  context 'as mrossi' do
    before :each do
      current_user User.find_by!(name: 'mrossi')
    end

    it 'should POST create (empty attribs)' do
      post 'create', params: {relationship: {}}
      expect(response.status).to eq(422)
    end

    it 'should POST create' do
      last_supper = Entity.find_by! name: 'The Last Supper'
      paris = Entity.find_by! name: 'Paris'
      attribs = {
        from_id: last_supper.id,
        relation_name: 'is related to',
        to_id: paris.id,
        properties: ['perhaps'],
        datings_attributes: [{label: 'time', dating_string: '1833'}]
      }

      post 'create', params: {relationship: attribs}
      expect_created_response
      relationship = Relationship.find(json['id'])
      expect(relationship.from.name).to eq('The Last Supper')
      expect(relationship.relation.name).to eq('is related to')
      expect(relationship.to.name).to eq('Paris')
      expect(relationship.properties.first).to eq('perhaps')
      expect(relationship.datings.first.dating_string).to eq('1833')
    end

    it 'should POST create (reverse direction)' do
      last_supper = Entity.find_by! name: 'The Last Supper'
      louvre = Entity.find_by! name: 'Louvre'
      params = {
        from_id: louvre.id,
        relation_name: 'is location of',
        to_id: last_supper.id
      }

      post 'create', params: {relationship: params}
      expect_created_response
      relationship = Relationship.find(json['id'])
      expect(relationship.from.name).to eq('The Last Supper')
      expect(relationship.relation.name).to eq('is located in')
      expect(relationship.to.name).to eq('Louvre')
    end

    it 'should PATCH update' do
      mona_lisa = Entity.find_by! name: 'Mona Lisa'
      last_supper = Entity.find_by! name: 'The Last Supper'
      relationship = Relationship.find_by!(from_id: mona_lisa.id, to_id: last_supper.id)
      patch 'update', params: {
        id: relationship.id,
        relationship: {properties: ['perhaps']}
      }
      expect_updated_response
      expect(relationship.reload.properties.first).to eq('perhaps')
    end

    it 'should DELETE destroy' do
      mona_lisa = Entity.find_by! name: 'Mona Lisa'
      last_supper = Entity.find_by! name: 'The Last Supper'
      relationship = Relationship.find_by!(from_id: mona_lisa.id, to_id: last_supper.id)
      delete 'destroy', params: {id: relationship.id}
      expect_deleted_response
      expect(Relationship.find_by(id: relationship.id)).to be_nil
    end
  end
end
