require "csv"

class AuditLog < ApplicationRecord
  belongs_to :tenant
  belongs_to :actor, class_name: "User"
  belongs_to :message_thread

  class MessageThreadNoteCreated < AuditLog
    def self.create_audit_record(note)
      create_record(
        object: note,
        new_value: note.note,
        message_thread: note.message_thread
      )
    end
  end

  class MessageThreadNoteChanged < AuditLog
    def self.create_audit_record(note)
      create_record(
        object: note,
        previous_value: note.note_previously_was,
        new_value: note.note,
        message_thread: note.message_thread
      )
    end
  end

  # TODO: Pre tagy sa asi budeme musiet subscribnut na nove eventy, kedze tu nevieme, ci to je destroy/create (dokonca teoreticky update)
  class MessageThreadTagChanged < AuditLog
    def self.create_audit_record(thread_tag)
      create_record(
        object: thread_tag,
        previous_value: thread_tag.tag.name_previously_was,
        new_value: thread_tag.tag.name,
        message_thread: thread_tag.message_thread
      )
    end
  end

  def self.create_record(object:, **args)
    create(
      tenant: Current.tenant,
      actor: Current.user,
      # TODO: SYSTEM alebo nil alebo nieco ine?
      actor_name: Current.user&.name || 'SYSTEM',
      happened_at: Time.current,
      changeset: object.previous_changes,
      thread_id_archived: args[:message_thread]&.id,
      thread_title: args[:message_thread]&.title,
      **args
    )
  end

  def self.to_csv
    CSV.generate do |csv|
      csv << column_names
      all.find_each do |audit_record|
        csv << audit_record.attributes.values_at(*column_names)
      end
    end
  end
end
