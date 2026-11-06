require "test_helper"

class GoodJobSchemaTest < ActiveSupport::TestCase
  # GoodJob ships new migrations in minor releases. This fails loudly when a gem
  # bump adds one without running `bin/rails g good_job:update` + `db:migrate`.
  test "all GoodJob migrations are applied" do
    assert GoodJob.migrated?, "Run `bin/rails g good_job:update` and `bin/rails db:migrate`"
  end
end
