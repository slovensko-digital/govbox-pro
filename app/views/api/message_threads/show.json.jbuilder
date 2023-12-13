json.tags @tags.pluck(:name)
json.messages(@messages.map { |message| url_for(message) })
