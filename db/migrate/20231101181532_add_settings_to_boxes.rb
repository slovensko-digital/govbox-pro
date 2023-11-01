class AddSettingsToBoxes < ActiveRecord::Migration[7.0]
  def change
    add_reference :boxes, :api_connection, foreign_key: true
    add_column :boxes, :settings, :jsonb

    Box.find_each do |box|
      box.settings[:obo] = ApiConnection.find_by(box: box).obo
      box.save!
    end

    remove_column :api_connection, :obo
  end
end
