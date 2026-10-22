require "test_helper"
require "helpers/good_job_helper"

# The deprecated `good_job_control_concurrency_with` was replaced by labelled
# `good_job_concurrency_rule`s (see the GoodJob README, "Migrating from
# concurrency keys to labels"). These tests cover the two ways such a migration
# can silently break the concurrency limits.
class ConcurrencyRulesTest < ActiveSupport::TestCase
  include GoodJobHelper

  setup do
    @thread = message_threads(:ssd_main_general)
    @fs_draft = messages(:fs_accountants_draft)
    @other_fs_draft = messages(:fs_accountants_draft2)
    @export = exports(:one)
  end

  test "the label does not depend on the identity of the argument objects" do
    # The label is resolved again when the job is performed, so it has to be
    # the same for a freshly loaded copy of the same record. Otherwise the
    # concurrency limits are not enforced anymore.
    job_arguments.each do |job_class, arguments|
      labels = 2.times.map { job_class.new(*arguments.call).good_job_labels }

      assert_equal labels.first, labels.last, "#{job_class} label is not reproducible"
    end
  end

  test "the total limit is enforced when a job is enqueued" do
    # Fs::ValidateMessageDraftJob allows a single unfinished job per message draft.
    Fs::ValidateMessageDraftJob.perform_later(@fs_draft)

    assert_equal 1, GoodJob::Job.count

    Fs::ValidateMessageDraftJob.perform_later(@fs_draft)

    assert_equal 1, GoodJob::Job.count,
                 "a second job with the same label should not be enqueued"
  end

  test "the total limit is enforced per label" do
    Fs::ValidateMessageDraftJob.perform_later(@fs_draft)
    Fs::ValidateMessageDraftJob.perform_later(@other_fs_draft)

    assert_equal 2, GoodJob::Job.count,
                 "jobs with a different label should not be blocked by the limit"
  end

  private

  # The arguments are built from freshly loaded records, so that the tests use
  # the same arguments as the job would get when it is performed.
  def job_arguments
    thread_arguments = -> { [@thread.id] }
    fs_draft_arguments = -> { [Fs::MessageDraft.find(@fs_draft.id)] }

    {
      ExportJob => -> { [@export] },
      NotifyFilterSubscriptionJob => -> { [nil, MessageThread.find(@thread.id), false] },
      Govbox::SubmitMessageDraftJob => -> { [MessageDraft.find(messages(:ssd_main_general_draft_two).id)] },
      ReindexAndNotifyFilterSubscriptionsJob => thread_arguments,
      Searchable::ReindexMessageThreadJob => thread_arguments,
      Fs::SubmitMessageDraftJob => fs_draft_arguments,
      Fs::ValidateMessageDraftJob => fs_draft_arguments,
      Fs::SyncBoxJob => -> { [boxes(:fs_accountants)] }
    }
  end
end
