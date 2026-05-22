require "application_system_test_case"

class Upvs::MessageDraftsTest < ApplicationSystemTestCase
  test "user can create message draft from template only if any UPVS box exists" do
    sign_in_as(:accountants_basic)

    visit message_threads_path

    click_button "Vytvoriť novú správu"
    assert_not has_link? "Napísať novú správu na slovensko.sk"
  end

  test "user can create message draft from Všeobecná agenda MessageTemplate" do
  end

  test "user can create message draft from CRAC MessageTemplate" do
  end

  test "user can upload message draft only if tenant messages limit not exceeded" do
    tenant = users(:basic).tenant
    tenant.enable_feature(:upvs, force: true)
    tenant.update(outbox_messages_limit: tenant.messages.outbox.count)

    sign_in_as(:basic)

    visit message_threads_path

    click_button "Vytvoriť novú správu"
    click_link "Napísať novú správu na slovensko.sk"

    click_button "Vytvoriť správu"

    assert_text "Dosiahli ste limit #{tenant.outbox_messages_limit} správ"
  end

  test "user can update message draft content" do
  end

  test "user can submit message draft" do
  end

  test "user can delete message draft" do
  end
end
