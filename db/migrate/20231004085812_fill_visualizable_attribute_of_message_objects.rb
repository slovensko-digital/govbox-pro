class FillVisualizableAttributeOfMessageObjects < ActiveRecord::Migration[7.0]
  def change
    MessageObject.find_each do |message_object|
      next unless message_object.form?

      message_object.update(visualizable: true) if (message_object.message.html_visualization.present? || message_object.message.try(:created_from_template?))
    end
  end
end
