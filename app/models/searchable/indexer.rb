class Searchable::Indexer
  MESSAGE_SEARCHABLE_FIELDS = [
    { name: :title, formatter: :string },
    { name: :sender_name, formatter: :string },
    { name: :html_visualization, formatter: :html_string },
  ]

  def self.index_message_thread(message_thread)
    record = ::Searchable::MessageThread.find_or_initialize_by(message_thread_id: message_thread.id)
    record.title = Searchable::IndexHelpers.searchable_string(message_thread.title)
    record.tag_ids = message_thread.tags.map(&:id)
    record.tag_names = Searchable::IndexHelpers.searchable_string(message_thread.tags.map(&:name).join(' ').gsub(/[:\/]/, " "))
    record.content = message_thread.messages.map { |message| message_to_searchable_string(message) }.join(' ')
    record.last_message_delivered_at = message_thread.last_message_delivered_at
    record.tenant_id = message_thread.folder.box.tenant_id
    record.box_id = message_thread.folder.box_id

    record.save!
  end

  def self.message_to_searchable_string(message)
    record_to_searchable_string(message, MESSAGE_SEARCHABLE_FIELDS)
  end

  def self.record_to_searchable_string(record, searchable_fields)
    searchable_fields.map do |searchable_field|
      field_name, formatter = searchable_field.fetch_values(:name, :formatter)
      value = record.public_send(field_name)

      case formatter
        when :string
          Searchable::IndexHelpers.searchable_string(value)
        when :html_string
          Searchable::IndexHelpers.html_to_searchable_string(value)
        else
          throw :unsupported_searchable_formatter
      end
    end.compact.join(' ')
  end

  def self.message_searchable_fields_changed?(message)
    MESSAGE_SEARCHABLE_FIELDS.any?{ |field| message.saved_changes.key?(field[:name].to_s) }
  end
end
