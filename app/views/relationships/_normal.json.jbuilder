json.id relationship.id
json.from_id relationship.from_id
json.to_id relationship.to_id
json.relation_id relationship.relation_id

json.properties relationship.properties
json.datings relationship.datings do |dating|
  json.extract!(dating,
    :id, :relationship_id, :label, :dating_string, :lock_version
  )
end