class CreateBoxGroups < ActiveRecord::Migration[7.1]
  def up
    create_table :box_groups do |t|
      t.references :box, null: false, foreign_key: true
      t.references :group, null: false, foreign_key: true

      t.timestamps
    end

    add_index :box_groups, [:box_id, :group_id], unique: true

    Tenant.find_each do |tenant|
      box_ids = tenant.boxes.pluck(:id)
      group_ids = tenant.groups.pluck(:id)

      timestamp = Time.current

      records = []
      group_ids.each do |group_id|
        box_ids.each do |box_id|
          records << {
            group_id: group_id,
            box_id: box_id,
            created_at: timestamp,
            updated_at: timestamp
          }
        end
      end

      BoxGroup.insert_all(records) if records.any?
    end
  end

  def down
    drop_table :box_groups
  end
end
