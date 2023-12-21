class ArchivedObjectTagComponent < ViewComponent::Base
  def initialize(archived_object, classes) # rubocop:disable Lint/MissingSuper,Metrics/MethodLength
    @classes = classes

    if archived_object.nil?
      @label = "Čaká na archiváciu"
      @color = "yellow"
      @icon = "clock"
    elsif !archived_object.signed?
      @label = "Nedá sa archivovať"
      @color = "gray"
      @icon = ""
    elsif !archived_object.valid_signature?
      @label = "Nedá sa overiť platnosť"
      @color = "red"
      @icon = "exclamation-triangle"
    elsif !archived_object.archived?
      @label = "Čaká na archiváciu"
      @color = "yellow"
      @icon = "clock"
    else
      @label = "Archivované"
      @color = "green"
      @icon = "archive-box"
    end
  end
end
