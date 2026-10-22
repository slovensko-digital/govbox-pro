require "test_helper"

class SidebarMenuTest < ActiveSupport::TestCase
  setup do
    Current.tenant = tenants(:ssd)
    Current.user = users(:admin)
  end

  teardown do
    Current.reset
  end

  test "menu entries and their icons are partial data" do
    menu = SidebarMenu.new("message_threads", "index", filters: [], tags: [])

    assert_equal menu.menu, menu.menu
    menu.menu.each do |entry|
      assert_kind_of Hash, entry
      assert_kind_of String, entry.fetch(:partial)
      icon = entry.fetch(:locals)[:icon]
      assert_kind_of String, icon.fetch(:partial) if icon
    end
  end

  test "optional admin links remain individual entries when their features are enabled" do
    menu = SidebarMenu.new("users", "index")
    Current.tenant.stub(:feature_enabled?, true) do
      Current.tenant.stub(:list_available_features, ["api"]) do
        entries = menu.menu

        assert entries.all? { |entry| entry.is_a?(Hash) }
        names = entries.map { |entry| entry.fetch(:locals, {})[:name] }
        assert_includes names, "API Prístup"
        assert_includes names, "Funkcie"
      end
    end
  end
end
