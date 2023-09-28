class AddColorToBoxes < ActiveRecord::Migration[7.0]
  def change
    create_enum :color, %w[slate gray zinc neutral stone red orange amber yellow lime green emerald teal cyan sky blue indigo violet purple fuchsia pink rose]
    change_table :boxes do |t|
      t.enum :color, enum_type: 'color'
    end
    Box.all.each do |box|
      box.color = Box.colors.keys[box.name.hash % Box.colors.size]
      box.short_name = box.name[0]
      box.save!
    end
  end
end
