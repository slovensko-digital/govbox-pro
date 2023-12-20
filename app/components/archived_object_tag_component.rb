class ArchivedObjectTagComponent < ViewComponent::Base
  def initialize(archived_object, classes) # rubocop:disable Lint/MissingSuper,Metrics/MethodLength
    @classes = classes

    if archived_object.nil?
      @text = "Čaká na archiváciu"
      @color = "yellow"
    elsif !archived_object.signed?
      @text = "Nedá sa archivovať"
      @color = "gray"
    elsif !archived_object.valid_signature?
      @text = "Nedá sa overiť platnosť"
      @color = "red"
    elsif !archived_object.archived?
      @text = "Čaká na archiváciu"
      @color = "yellow"
    else
      @text = "Archivované"
      @color = "green"
    end
  end
end
