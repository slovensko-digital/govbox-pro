class RemoveToBeSignedAttributeFromMessageObjects < ActiveRecord::Migration[7.1]
  def change
    remove_column :message_objects, :to_be_signed
  end
end
