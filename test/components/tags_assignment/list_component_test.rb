require "test_helper"

class TagsAssignment::ListComponentTest < ViewComponent::TestCase
  test "list preparation and rendering use two queries regardless of tag count" do
    tenant = tenants(:ssd)
    100.times { |i| tenant.simple_tags.create!(name: "Query measurement #{i}") }

    [1, 100].each do |size|
      scope = tenant.simple_tags.visible.order(:name).limit(size)
      manageable_scope = scope.manageable_by(users(:basic))
      filter = nil
      component = nil

      queries = record_queries do
        filter = TagsFilter.new(tag_scope: scope, manageable_scope: manageable_scope)
        component = build_component(filter)
        render_inline(component)
      end

      assert_equal 2, queries.size, queries.join("\n")
      assert_equal size, filter.all_tags.size
      assert_empty record_queries { 10.times { filter.all_tags.each { |tag| component.manageable?(tag) } } }
    end
  end

  test "without a manageable scope the loaded tags supply all ids in one query" do
    scope = tenants(:ssd).simple_tags.visible.order(:name)
    filter = nil
    queries = record_queries do
      filter = TagsFilter.new(tag_scope: scope)
      render_inline(build_component(filter))
    end

    assert_equal 1, queries.size, queries.join("\n")
    assert_equal filter.filtered_ids, filter.manageable_ids
  end

  test "search retains database case insensitive and accent insensitive filtering" do
    tag = tenants(:ssd).simple_tags.create!(name: "Účtovníctvo")
    scope = tenants(:ssd).simple_tags.visible.order(:name)
    filter = nil
    queries = record_queries do
      filter = TagsFilter.new(tag_scope: scope, manageable_scope: scope.without_access, filter_query: "UCTOV")
      render_inline(build_component(filter))
    end

    assert_equal 3, queries.size, queries.join("\n")
    assert_equal Set.new([tag.id]), filter.filtered_ids
    assert_selector "#new_tags_assignments_#{tag.id}"
  end

  test "locked checkboxes use initial state and manageable checkboxes use edited state" do
    finance = tags(:ssd_finance)
    print_tag = tags(:ssd_print)
    scope = tenants(:ssd).simple_tags.where(id: [finance.id, print_tag.id])
    filter = TagsFilter.new(tag_scope: scope, manageable_scope: scope.manageable_by(users(:basic)))
    assignments = {
      init: { finance.id.to_s => "+", print_tag.id.to_s => "-" },
      new: { finance.id.to_s => "-", print_tag.id.to_s => "+" }
    }
    render_inline(build_component(filter, assignments))

    assert_selector "#new_tags_assignments_#{finance.id}[disabled][checked]"
    assert_selector "span[title='#{I18n.t('tags_assignment.not_manageable')}']", text: finance.name
    assert_no_selector "input[name='tags_assignments[new][#{finance.id}]']", visible: :all
    assert_selector "#new_tags_assignments_#{print_tag.id}[checked]:not([disabled])"
  end

  test "locked mixed checkbox retains its initial state when no new value was submitted" do
    finance = tags(:ssd_finance)
    scope = tenants(:ssd).simple_tags.where(id: finance.id)
    filter = TagsFilter.new(tag_scope: scope, manageable_scope: scope.manageable_by(users(:basic)))
    component = build_component(filter, { init: { finance.id.to_s => "=" }, new: {} })
    checkbox = component.checkbox_for(finance, manageable: false)

    assert checkbox.indeterminate?
    assert checkbox.checked?
    assert_equal "=", checkbox.value
  end

  private

  def build_component(filter, assignments = { init: {}, new: {} })
    TagsAssignment::ListComponent.new(tags_filter: filter, tags_assignments: assignments, create_tag_path: "/tags")
  end

  def record_queries
    queries = []
    subscriber = ->(_name, _start, _finish, _id, payload) do
      queries << payload[:sql] unless payload[:name].in?(%w[SCHEMA TRANSACTION]) || payload[:cached]
    end
    ActiveRecord::Base.uncached do
      ActiveSupport::Notifications.subscribed(subscriber, "sql.active_record") { yield }
    end
    queries
  end
end
