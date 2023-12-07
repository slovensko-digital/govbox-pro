class AddColorToTags < ActiveRecord::Migration[7.0]
  def change
    change_table :tags   do |t|
      t.enum :color, enum_type: 'color'
    end
  end
end
