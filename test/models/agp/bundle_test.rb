require "test_helper"

class Agp::BundleTest < ActiveSupport::TestCase
  test "generate_uuid_from_message_objects depends on signer user" do
    objects = [message_objects(:ssd_main_general_draft_two_form)]

    first_uuid = Agp::Bundle.generate_uuid_from_message_objects(objects, signer_user: users(:ssd_signer))
    second_uuid = Agp::Bundle.generate_uuid_from_message_objects(objects, signer_user: users(:ssd_signer2))

    refute_equal first_uuid, second_uuid
  end

  test "find_or_initialize_from_message_objects stores signer user on contracts" do
    bundle = Agp::Bundle.find_or_initialize_from_message_objects(
      tenants(:ssd),
      [message_objects(:ssd_main_general_draft_two_form)],
      signer_user: users(:ssd_signer)
    )

    assert_equal users(:ssd_signer), bundle.contracts.first.signer_user
  end
end
