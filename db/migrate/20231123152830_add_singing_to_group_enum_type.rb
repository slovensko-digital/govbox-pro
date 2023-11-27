class AddSingingToGroupEnumType < ActiveRecord::Migration[7.0]
  def change
    execute "ALTER TYPE group_type ADD VALUE 'SIGNING';"
  end
end
