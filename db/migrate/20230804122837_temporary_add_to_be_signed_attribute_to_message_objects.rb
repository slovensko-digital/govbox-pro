class TemporaryAddToBeSignedAttributeToMessageObjects < ActiveRecord::Migration[7.0]
  def up
    add_column :message_objects, :to_be_signed, :boolean

    MessageObject.update_all(
      to_be_signed: false
    )

    change_column :message_objects, :to_be_signed, :boolean, null: false, default: false
  end
end
