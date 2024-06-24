class ChangeTypeNullOnFilters < ActiveRecord::Migration[7.1]
  def change
    reversible do |dir|
      dir.up do
        Filter.find_each do |filter|
          if filter.type.nil?
            filter.update!(type: 'FulltextFilter')
          end
        end
      end
    end
    change_column_null :filters, :type, false
  end
end
