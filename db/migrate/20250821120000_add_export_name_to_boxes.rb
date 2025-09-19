class AddExportNameToBoxes < ActiveRecord::Migration[7.1]
  def up
    add_column :boxes, :export_name, :string
    # Simple backfill: copy current derived official_name into export_name.
    # We use update_columns to skip validations/callbacks (faster, avoids before_validation overwriting logic).
    Box.reset_column_information
    say_with_time "Backfilling boxes.export_name" do
      Box.find_each do |box|
        box.update_columns(export_name: box.official_name)
      end
    end

    change_column_null :boxes, :export_name, false
  end

  def down
    remove_column :boxes, :export_name
  end
end
