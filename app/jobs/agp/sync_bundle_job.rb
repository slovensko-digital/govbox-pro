module Agp
  # Fallback for lost webhooks: with poll: true the job keeps checking the bundle with a growing interval
  # until all its contracts are signed or the polling period runs out.
  class SyncBundleJob < ApplicationJob
    discard_on ActiveJob::DeserializationError

    def perform(bundle, poll: false)
      return unless bundle.created?

      if poll && bundle.polling_expired?
        Rails.logger.info("AGP bundle #{bundle.bundle_identifier} was not signed in time, polling stopped")
        return bundle.expire!
      end

      bundle.sync!

      self.class.set(wait: bundle.next_polling_in).perform_later(bundle, poll: true) if poll && bundle.reload.created?
    end
  end
end
