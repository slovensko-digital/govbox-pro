class AddHtmlVisualizationToMessages < ActiveRecord::Migration[7.0]
  def change
    add_column :messages, :html_visualization, :text, null: false
  end
end
