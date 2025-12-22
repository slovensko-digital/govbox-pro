require "test_helper"

class Admin::BoxesIndexViewTest < ActionView::TestCase
  include ApplicationHelper

  def setup
    @tenant = tenants(:accountants)
    @tenant.update!(feature_flags: (@tenant.feature_flags + ['fs_api']).uniq)
    @inactive_box = boxes(:fs_accountants)
    @inactive_box.update!(active: false)
    @active_box = boxes(:fs_delegate)
    Current.tenant = @tenant
    view.lookup_context.prefixes = ["admin/boxes"]
  end

  def teardown
    Current.reset
  end

  test "renders inactive badge for inactive FS box" do
    @boxes = @tenant.boxes

    render template: "admin/boxes/index"

    assert_includes rendered, "Neaktívna schránka"
    assert_includes rendered, @inactive_box.name
  end
end
