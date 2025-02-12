require 'test_helper'

class MessageDraftsControllerTest < ActionController::TestCase
  setup do
    session[:login_expires_at] = Time.now + 1.day
    Current.user = users(:basic)
    session[:user_id] = Current.user.id
  end
  test "should destroy draft with status created" do
    # draft should be destroyed if not yet submitted
    message_draft = messages(:ssd_main_draft)
    delete :destroy, params: { id: message_draft.id }
    assert_raises(ActiveRecord::RecordNotFound) do
      MessageDraft.find(message_draft.id)
    end
  end
  test "should not destroy draft that is being submitted" do
    message_draft = messages(:ssd_main_draft)
    message_draft.metadata[:status] = "being_submitted"
    message_draft.save!
    delete :destroy, params: { id: message_draft.id }
    assert_equal "Správu nie je možné zmazať po zaradení na odoslanie", flash[:alert]
    assert MessageDraft.exists?(message_draft.id)
  end
end
