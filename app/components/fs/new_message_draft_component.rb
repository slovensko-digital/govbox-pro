class Fs::NewMessageDraftComponent < ViewComponent::Base
  DEFAULT_CLASSES = 'bg-gray-50 border border-gray-300 text-gray-900 focus:ring-blue-500 focus:border-blue-500'
  ERROR_CLASSES = 'bg-red-50 border border-red-500 text-red-900 placeholder-red-700 focus:ring-red-500 focus:border-red-500'

  def initialize(message:, selected_box: nil, boxes:)
    @message = message
    @selected_box = selected_box
    @boxes = boxes
  end
end
