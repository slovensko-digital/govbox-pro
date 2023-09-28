class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  class FailedToAcquireLockError < StandardError
  end

  def self.with_advisory_lock!(lock_name, options = {}, &block)
    result = with_advisory_lock_result(lock_name, options, &block)
    if result.lock_was_acquired?
      result.result
    else
      raise FailedToAcquireLockError
    end
  end
end
