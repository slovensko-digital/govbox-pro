class CreateGroups < ActiveRecord::Migration[7.0]
  def change
    create_enum :group_type, ['ALL', 'USER', 'CUSTOM', 'ADMIN']
    create_table :groups do |t|
      t.string :name, null: false
      t.references :tenant, null: false, foreign_key: true
      t.enum :group_type, enum_type: 'group_type', null: false

      t.timestamps
    end
  end
end
