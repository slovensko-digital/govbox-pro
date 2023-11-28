class CreateMessageTemplates < ActiveRecord::Migration[7.0]
  def change
    create_table :message_templates do |t|
      t.references :tenant, foreign_key: true
      t.string :name, null: false
      t.text :content, null: false
      t.string :type
      t.jsonb :metadata
      t.boolean :system, null:false, default: false

      t.timestamps
    end
  end
end
