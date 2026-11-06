# Adopted framework defaults for Rails 7.2 (config.load_defaults 7.2):
#
# - yjit enabled, PostgreSQL date decoding, migration timestamp validation
#
# active_job.enqueue_after_transaction_commit (:default) is deliberately left at
# the application behaviour: GoodJob controls enqueueing after commit, and tests
# that process the GoodJob queue opt in via test/helpers/good_job_helper.rb.
