require "application_system_test_case"
class NewMessageNotificationTest < ApplicationSystemTestCase
  setup do
    Searchable::MessageThread.reindex_all

    silence_warnings do
      @old_value = MessageThreadCollection.const_get("PER_PAGE")
      MessageThreadCollection.const_set("PER_PAGE", 1)
    end

    sign_in_as(:admin)
  end

  test 'should notify user on new message' do
    govbox_message = govbox_messages(:one)

    Govbox::Message.create_message_with_thread!(govbox_message)
    travel_to(15.minutes.from_now) { GoodJob.perform_inline }
    message = Message.last

    visit message_thread_path(message.thread)

    govbox_message_2 = govbox_messages(:three)

    Govbox::Message.create_message_with_thread!(govbox_message_2)
    travel_to(2.seconds.from_now) { GoodJob.perform_inline }

    assert_link I18n.t "new_message_link"
    click_link I18n.t "new_message_link"
    assert_text "MySubject"
  end
end
