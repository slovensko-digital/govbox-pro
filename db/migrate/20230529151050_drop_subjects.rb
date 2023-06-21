class DropSubjects < ActiveRecord::Migration[7.0]
  def up
    remove_column :drafts_imports, :subject_id
    remove_column :drafts, :subject_id
    drop_table 'subjects'
  end

  def down
    raise ActiveRecord::IrreversibleMigration, 'cannot recover subjects table'
  end
end
