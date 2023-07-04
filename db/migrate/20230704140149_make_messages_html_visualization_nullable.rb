class MakeMessagesHtmlVisualizationNullable < ActiveRecord::Migration[7.0]
  def change
    change_column_null :messages, :html_visualization, true
  end
end
