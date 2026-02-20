json.array! @boxes do |box|
  json.id box.id
  json.name box.name
  json.short_name box.short_name
  json.export_name box.export_name
  json.uri box.uri
  json.type box.type
  json.obo box.settings_obo if box.respond_to?(:settings_obo)
  json.dic box.settings_dic if box.respond_to?(:settings_dic)
  json.active box.active
end
