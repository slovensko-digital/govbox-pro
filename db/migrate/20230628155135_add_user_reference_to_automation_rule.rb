class AddUserReferenceToAutomationRule < ActiveRecord::Migration[7.0]
  def change
    add_reference :automation_rules, :user, null: false, foreign_key: true
  end
end
