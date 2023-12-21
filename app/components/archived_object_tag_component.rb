class ArchivedObjectTagComponent < ViewComponent::Base
  def initialize(archived_object) # rubocop:disable Lint/MissingSuper,Metrics/MethodLength
    if archived_object.nil?
      @label = "Čaká na archiváciu"
      @color = "yellow"
      @icon = "clock"
    elsif !archived_object.signed?
      @label = nil
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

  def render?
    @label.present?
  end
end
