class ArchivedObjectTagComponent < ViewComponent::Base
  def initialize(archived_object, classes)
    @classes = classes
    @archived_object = archived_object
  end
end
