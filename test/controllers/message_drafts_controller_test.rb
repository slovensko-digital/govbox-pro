require 'test_helper'

class MessageDraftsControllerTest < ActionController::TestCase
  include ActiveJob::TestHelper

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
  
  test "should not destroy draft that is being submitted" do
    message_draft = messages(:ssd_main_draft)
    message_draft.metadata[:status] = "being_submitted"
    message_draft.save!
    delete :destroy, params: { id: message_draft.id }
    assert_equal "Správu nie je možné zmazať po zaradení na odoslanie", flash[:alert]
    assert MessageDraft.exists?(message_draft.id)
  end

  # apply_corrected_xml

  test "apply_corrected_xml replaces blob and re-enqueues validation" do
    Current.user = users(:accountants_basic)
    session[:user_id] = Current.user.id

    message_draft = messages(:fs_accountants_draft_uzmujv14_with_attachment)
    corrected_xml = "<CorrectedForm>fixed</CorrectedForm>"
    message_draft.update!(metadata: message_draft.metadata.merge(
      "status" => "invalid",
      "validation_errors" => {
        "errors"        => [],
        "diff_errors"   => ["FS zmenil IČO"],
        "diff_warnings" => [],
        "corrected_xml" => corrected_xml
      }
    ))

    Fs::MessageHelper.stub(:build_html_visualization_from_form, nil) do
      assert_enqueued_with(job: Fs::ValidateMessageDraftJob) do
        post :apply_corrected_xml, params: { id: message_draft.id }
      end
    end

    assert_redirected_to message_thread_path(message_draft.thread)
    assert_equal "Opravená verzia XML bola použitá, prebieha nová validácia správy", flash[:notice]

    message_draft.reload
    assert_equal corrected_xml, message_draft.form_object.content
    assert_equal({}, message_draft.metadata["validation_errors"])
    assert_equal "being_validated", message_draft.metadata["status"]
  end

  test "apply_corrected_xml is blocked when draft is already submitted" do
    Current.user = users(:accountants_basic)
    session[:user_id] = Current.user.id

    message_draft = messages(:fs_accountants_draft_uzmujv14_with_attachment)
    message_draft.update!(metadata: message_draft.metadata.merge(
      "status" => "submitted",
      "validation_errors" => { "corrected_xml" => "<xml>corrected</xml>", "diff_errors" => ["FS zmenil IČO"] }
    ))
    original_blob = message_draft.form_object.content

    post :apply_corrected_xml, params: { id: message_draft.id }

    assert_redirected_to message_thread_path(message_draft.thread)
    assert_equal "Správu nie je možné upraviť po zaradení na odoslanie", flash[:alert]
    assert_equal original_blob, message_draft.reload.form_object.content
  end

  test "apply_corrected_xml is blocked when draft is being_submitted" do
    Current.user = users(:accountants_basic)
    session[:user_id] = Current.user.id

    message_draft = messages(:fs_accountants_draft_uzmujv14_with_attachment)
    message_draft.update!(metadata: message_draft.metadata.merge(
      "status" => "being_submitted",
      "validation_errors" => { "corrected_xml" => "<xml>corrected</xml>", "diff_errors" => ["FS zmenil IČO"] }
    ))

    post :apply_corrected_xml, params: { id: message_draft.id }

    assert_equal "Správu nie je možné upraviť po zaradení na odoslanie", flash[:alert]
  end

  test "apply_corrected_xml shows error when corrected_xml is missing" do
    Current.user = users(:accountants_basic)
    session[:user_id] = Current.user.id

    message_draft = messages(:fs_accountants_draft_uzmujv14_with_attachment)
    message_draft.update!(metadata: message_draft.metadata.merge(
      "status" => "invalid",
      "validation_errors" => { "diff_errors" => ["FS zmenil IČO"], "corrected_xml" => nil }
    ))

    post :apply_corrected_xml, params: { id: message_draft.id }

    assert_redirected_to message_thread_path(message_draft.thread)
    assert_equal "Opravená verzia XML od Finančnej správy nie je k dispozícii", flash[:alert]
  end

  test "apply_corrected_xml refuses to overwrite a signed form" do
    Current.user = users(:accountants_basic)
    session[:user_id] = Current.user.id

    message_draft = messages(:fs_accountants_draft_uzmujv14_with_attachment)
    message_draft.form_object.update!(is_signed: true)
    original_blob = message_draft.form_object.content
    message_draft.update!(metadata: message_draft.metadata.merge(
      "status" => "invalid",
      "validation_errors" => { "diff_errors" => ["FS zmenil IČO"], "corrected_xml" => "<xml>corrected</xml>" }
    ))

    assert_no_enqueued_jobs only: Fs::ValidateMessageDraftJob do
      post :apply_corrected_xml, params: { id: message_draft.id }
    end

    assert_equal "Opravená verzia XML od Finančnej správy nie je k dispozícii", flash[:alert]
    assert_equal original_blob, message_draft.reload.form_object.content
  end
end
