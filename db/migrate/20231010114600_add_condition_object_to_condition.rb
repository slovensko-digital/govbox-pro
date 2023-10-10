class AddConditionObjectToCondition < ActiveRecord::Migration[7.0]
  def change
    change_table :automation_conditions do |t|
      t.references :condition_object, polymorphic: true
    end
  end
end
