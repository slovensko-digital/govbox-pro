class AddUnaccentToDb < ActiveRecord::Migration[7.0]
  def change
    execute <<-SQL
      CREATE extension IF NOT EXISTS unaccent;
    SQL
  end
end
