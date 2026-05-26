require 'test_helper'

class MessageDraftsControllerTest < ActionController::TestCase
  setup do
    session[:login_expires_at] = Time.now + 1.day
    Current.user = users(:basic)
    session[:user_id] = Current.user.id
  end
  test "should destroy draft if it was not yet submitted" do
    message_draft = messages(:ssd_main_draft)
    delete :destroy, params: { id: message_draft.id }
    assert_raises(ActiveRecord::RecordNotFound) do
      MessageDraft.find(message_draft.id)
    end
  end

  test "should destroy draft together with all agp contracts referencing its message objects" do
    message_draft = messages(:ssd_main_draft)
    message_object = message_objects(:ssd_main_draft_form)
    tenant = tenants(:ssd)

    bundle_one = Agp::Bundle.create!(tenant: tenant, bundle_identifier: SecureRandom.uuid)
    bundle_two = Agp::Bundle.create!(tenant: tenant, bundle_identifier: SecureRandom.uuid)

    Agp::Contract.create!(
      bundle: bundle_one,
      message_object: message_object,
      message_object_updated_at: message_object.updated_at,
      contract_identifier: SecureRandom.uuid
    )
    Agp::Contract.create!(
      bundle: bundle_two,
      message_object: message_object,
      message_object_updated_at: message_object.updated_at,
      contract_identifier: SecureRandom.uuid
    )

    assert_equal 2, Agp::Contract.where(message_object: message_object).count

    assert_difference('Agp::Contract.count', -2) do
      delete :destroy, params: { id: message_draft.id }
    end

    assert_redirected_to message_threads_path
    assert_equal "Správa bola zmazaná", flash[:notice]
    assert_not MessageDraft.exists?(message_draft.id)
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
