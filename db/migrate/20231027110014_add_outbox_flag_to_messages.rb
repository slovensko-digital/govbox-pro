class AddOutboxFlagToMessages < ActiveRecord::Migration[7.0]
  def up
    add_column :messages, :outbox, :boolean, default: false

    Message.find_each do |message|
      outbox_tags = Tag.where('name LIKE ?', 'slovensko.sk:SentItems%').where(tenant: message.thread.folder.box.tenant)

      message.update(
        outbox: (message.tags & outbox_tags).any?
      )

      next if message.collapsed?
      message.thread.messages.outbox.where(uuid: message.metadata["reference_id"]).take&.update(
        collapsed: true
      )
    end

    change_column :messages, :outbox, :boolean, null: false, default: false
  end

  def down
    remove_column :messages, :outbox
  end
end
