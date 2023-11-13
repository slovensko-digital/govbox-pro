class AuditLog < ApplicationRecord
  self.table_name = :go_audit_logs
  belongs_to :tenant
  belongs_to :user
  belongs_to :primary_object, polymorphic: true, optional: true
  belongs_to :secondary_object, polymorphic: true, optional: true

  class MessageThreadNoteCreated < AuditLog
    def self.create_audit_record(object)
      @description = "User created note on thread"
      @new_value_string = object.note
      @primary_object = object.message_thread
      @secondary_object = object
      create_record
    end
  end

  class MessageThreadNoteChanged < AuditLog
    def self.create_audit_record(object)
      @description = "User changed note on thread"
      @original_value_string = object.note_previously_was
      @new_value_string = object.note
      @primary_object = object.message_thread
      @secondary_object = object
      create_record
    end
  end

  # TODO: Pre tagy sa asi budeme musiet subscribnut na nove eventy, kedze tu nevieme, ci to je destroy/create (dokonca teoreticky update)
  class MessageThreadTagChanged < AuditLog
    def self.create_audit_record(object)
      @description = "Tag was changed on thread"
      @original_value_string = object.tag.name_previously_was
      @primary_object = object.message_thread
      @secondary_object = object
      create_record
    end
  end

  def self.create_record
    create(
      tenant: Current.tenant,
      user: Current.user,
      # TODO: SYSTEM alebo nil alebo nieco ine?
      user_name: Current.user&.name || 'SYSTEM',
      event_timestamp: Time.current,
      primary_object: @primary_object,
      secondary_object: @secondary_object,
      description: @description,
      original_value_string: @original_value_string,
      new_value_string: @new_value_string
    )
  end
end
