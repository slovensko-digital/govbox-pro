require "test_helper"

class Govbox::ProcessMessageJobTest < ActiveJob::TestCase
  test "does not collapse outbox message if only technical messages received" do
    govbox_message = govbox_messages(:ssd_outbox)

    Govbox::ProcessMessageJob.new.perform(govbox_message)

    message = Message.find_by(uuid: govbox_message.message_id)

    assert_equal message.reload.collapsed?, false
  end

  test "collapses outbox message after new non-technical referring message received" do
    outbox_govbox_message = govbox_messages(:ssd_outbox)
    Govbox::ProcessMessageJob.new.perform(outbox_govbox_message)

    outbox_message = Message.find_by(uuid: outbox_govbox_message.message_id)
    assert_equal outbox_message.reload.collapsed?, false

    inbox_govbox_message = govbox_messages(:ssd_referring_to_outbox_message)
    inbox_govbox_message.update!(correlation_id: outbox_govbox_message.correlation_id)
    Govbox::ProcessMessageJob.new.perform(inbox_govbox_message)

    assert outbox_message.reload.collapsed?
  end

  test "collapses outbox message if non-technical referring message previously received" do
    inbox_govbox_message = govbox_messages(:ssd_referring_to_outbox_message)
    Govbox::ProcessMessageJob.new.perform(inbox_govbox_message)

    outbox_govbox_message = govbox_messages(:ssd_outbox)
    Govbox::ProcessMessageJob.new.perform(outbox_govbox_message)

    outbox_message = Message.find_by(uuid: outbox_govbox_message.message_id)

    assert outbox_message.reload.collapsed?
  end
end
