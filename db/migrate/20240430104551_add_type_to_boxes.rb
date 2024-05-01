class AddTypeToBoxes < ActiveRecord::Migration[7.1]
  def up
    add_column :boxes, :type, :string

    Box.find_each do |box|
      box.update(type: 'Upvs::Box')
    end
  end
end
