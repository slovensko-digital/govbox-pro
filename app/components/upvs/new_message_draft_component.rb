class Upvs::NewMessageDraftComponent < ViewComponent::Base
  DEFAULT_CLASSES = 'bg-gray-50 border border-gray-300 text-gray-900 focus:ring-blue-500 focus:border-blue-500'
  ERROR_CLASSES = 'bg-red-50 border border-red-500 text-red-900 placeholder-red-700 focus:ring-red-500 focus:border-red-500'

  def initialize(message:, templates_list:, boxes:, recipients_list: nil, selected_box: nil, selected_message_template: nil)
    @message = message
    @templates_list = templates_list
    @boxes = boxes
    @recipients_list = recipients_list
    @selected_box = selected_box
    @selected_message_template = selected_message_template
  end
end
