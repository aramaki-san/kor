json.total @total
json.per_page @per_page
json.page @page

json.records @records do |record|
  json.partial! 'customized', {
    kor_collection: record,
    directed_relationship: record,
    additions: ['all']
  }
end
