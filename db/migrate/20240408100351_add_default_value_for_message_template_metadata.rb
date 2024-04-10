class AddDefaultValueForMessageTemplateMetadata < ActiveRecord::Migration[7.1]
  def up
    change_column :message_templates, :metadata, :jsonb, default: {}

    ::MessageTemplate.where(metadata: nil).update(metadata: {})
  end

  def down
    change_column :message_templates, :metadata, :jsonb, default: nil
  end
end
