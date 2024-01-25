require "test_helper"

class Govbox::CheckMessagesMappingJobTest < ActiveJob::TestCase
  test "raises error if unmapped messages present" do
    assert_raise do
      Govbox::CheckMessagesMappingJob.new.perform
    end
  end
end
