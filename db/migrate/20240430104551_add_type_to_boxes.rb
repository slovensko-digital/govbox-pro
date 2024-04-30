class AddTypeToBoxes < ActiveRecord::Migration[7.1]
  def up
    add_column :boxes, :type, :string
  end
end
