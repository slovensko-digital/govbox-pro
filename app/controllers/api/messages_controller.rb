class Api::MessagesController < Api::TenantController
  before_action :set_en_locale
  before_action :check_content_type, only: :create

  include Upvs::MessageDraftConcern

  ALLOWED_CONTENT_TYPES = ['application/json;type=upvs']

  def create
    case message_type(raw_content_type)
    when 'upvs'
      create_upvs_message_draft
    end
  end

  def show
    @message = @tenant.messages.find(params[:id])
  end

  private

  def raw_content_type
    request.content_type
  end

  def message_type(content_type)
    content_type.match(/(application\/json\;type\=)(.*)/)[2]
  end

  def check_content_type
    render_bad_request(ActionController::BadRequest.new("Disallowed Content-Type: #{raw_content_type}")) unless raw_content_type.in?(ALLOWED_CONTENT_TYPES)
  end
end
