class AddNoteToSearchableMessageThread < ActiveRecord::Migration[7.0]
  def change
    add_column :searchable_message_threads, :note, :string

    Searchable::MessageThread.reset_column_information

    Searchable::MessageThread.update_all(note: "")

    change_column_null :searchable_message_threads, :note, false
  end
end
