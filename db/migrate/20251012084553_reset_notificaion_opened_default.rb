class ResetNotificaionOpenedDefault < ActiveRecord::Migration[7.1]
  def change
    change_column_default :users, :notifications_opened, false
    User.update_all(notifications_opened: true) # mark all read by default
  end
end
