# == Schema Information
#
# Table name: tags
#
#  id               :bigint           not null, primary key
#  color            :enum
#  external_name    :string
#  icon             :string
#  name             :string           not null
#  tag_groups_count :integer          default(0), not null
#  type             :string           not null
#  visible          :boolean          default(TRUE), not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  owner_id         :bigint
#  tenant_id        :bigint           not null
#
require "test_helper"

class EverythingTagTest < ActiveSupport::TestCase
  test "adds everything tag to every thread" do
    box = boxes(:ssd_main)
    thread = box.message_threads.create!(
      title: 'Test',
      original_title: 'Test',
      delivered_at: Time.current,
      last_message_delivered_at: Time.current
    )

    assert_includes thread.tags, box.tenant.everything_tag
  end
end
