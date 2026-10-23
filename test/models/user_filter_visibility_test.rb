require "test_helper"

class UserFilterVisibilityTest < ActiveSupport::TestCase
  test "preference belongs to an available definition and has a positive position" do
    preference = UserFilterVisibility.new(user: users(:basic), filter: filters(:one), position: 1)
    assert preference.save
    assert_not preference.dup.valid?
    preference.filter = filters(:solver_one)
    assert_not preference.valid?
    preference.filter = filters(:two)
    assert_not preference.valid?
    filters(:two).update!(common: true)
    preference.filter.reload
    assert preference.valid?
    preference.position = 0
    assert_not preference.valid?
  end

  test "database enforces one preference per user and filter" do
    preference = UserFilterVisibility.create!(user: users(:basic), filter: filters(:one), position: 1)
    assert_raises ActiveRecord::RecordNotUnique do
      UserFilterVisibility.transaction(requires_new: true) do
        UserFilterVisibility.insert_all!([preference.attributes.except("id")])
      end
    end
  end

  test "filter cleanup removes preferences" do
    preference = UserFilterVisibility.create!(user: users(:basic), filter: filters(:one), position: 1)
    filters(:one).destroy!
    assert_not UserFilterVisibility.exists?(preference.id)
  end

  test "user cleanup destroys personal definitions but retains common attribution safely" do
    user = User.create!(tenant: tenants(:ssd), name: "Filter owner", email: "filter-owner@example.com")
    personal = Filter.create!(tenant: user.tenant, author: user, name: "Personal", query: "cleanup-personal")
    common = Filter.create!(tenant: user.tenant, author: user, name: "Common", query: "cleanup-common", common: true)
    preference = user.user_filter_visibilities.find_by!(filter: common)
    user.destroy!
    assert_not UserFilterVisibility.exists?(preference.id)
    assert_not Filter.exists?(personal.id)
    assert Filter.exists?(common.id)
    assert_nil common.reload.author_id
  end
end
