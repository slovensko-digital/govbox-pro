class SetEmptyObjectAsDefaultForBoxesSettings < ActiveRecord::Migration[7.1]
  def up
    Box.where(settings: nil).update_all(settings: {})
    change_column_default :boxes, :settings, {}
    change_column_null :boxes, :settings, false
  end

  def down
    change_column_default :boxes, :settings, nil
    change_column_null :boxes, :settings, true
  end
end
