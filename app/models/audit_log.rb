require "csv"

class AuditLog < ApplicationRecord
  belongs_to :tenant
  belongs_to :user
  belongs_to :thread, class_name: "MessageThread"

  class MessageThreadNoteCreated < AuditLog
    def self.create_audit_record(object)
      create_record(
        object: object,
        new_value: object.note,
        thread: object.message_thread
      )
    end
  end

  class MessageThreadNoteChanged < AuditLog
    def self.create_audit_record(object)
      create_record(
        object: object,
        previous_value: object.note_previously_was,
        new_value: object.note,
        thread: object.message_thread
      )
    end
  end

  # TODO: Pre tagy sa asi budeme musiet subscribnut na nove eventy, kedze tu nevieme, ci to je destroy/create (dokonca teoreticky update)
  class MessageThreadTagChanged < AuditLog
    def self.create_audit_record(object)
      create_record(
        object: object,
        previous_value: object.tag.name_previously_was,
        new_value: object.tag.name,
        thread: object.message_thread
      )
    end
  end

  def self.create_record(object:, **args)
    create(
      tenant: Current.tenant,
      user: Current.user,
      # TODO: SYSTEM alebo nil alebo nieco ine?
      user_name: Current.user&.name || 'SYSTEM',
      happened_at: Time.current,
      changeset: object.previous_changes,
      thread_id_archived: args[:thread]&.id,
      thread_name: args[:thread]&.title,
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
