require "test_helper"

class RelationChangesTagsTest < ActiveSupport::TestCase
  test "missing new assignments mean no changes and still allow creating a tag" do
    scope = tenants(:ssd).simple_tags.visible
    changes = RelationChanges::Tags.new(tag_scope: scope, tags_assignments: { init: { tags(:ssd_finance).id.to_s => "+" } })

    assert_equal 0, changes.number_of_changes
    assert_empty changes.new_assignments

    tag = tenants(:ssd).simple_tags.create!(name: "New classification")
    changes.add_new_tag(tag)
    assert_equal [tag], changes.diff.to_add
  end

  test "diff ignores locked and out of scope ids while keeping permitted changes" do
    finance = tags(:ssd_finance)
    legal = tags(:ssd_legal)
    hidden = tags(:ssd_hidden)
    scope = tenants(:ssd).simple_tags.visible
    changes = RelationChanges::Tags.new(
      tag_scope: scope,
      manageable_scope: scope.manageable_by(users(:basic)),
      tags_assignments: {
        init: { finance.id.to_s => "+", legal.id.to_s => "+" },
        new: { finance.id.to_s => "-", legal.id.to_s => "-", hidden.id.to_s => "+", "0" => "+" }
      }
    )

    assert_empty changes.diff.to_add
    assert_equal [legal], changes.diff.to_remove
    assert_equal 1, changes.number_of_changes
  end
end
