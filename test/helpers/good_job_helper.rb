# These tests exercise the persisted GoodJob queue via GoodJob.perform_inline.
module GoodJobHelper
  include ActiveJob::TestHelper

  def queue_adapter_for_test
    GoodJob::Adapter.new
  end
end
