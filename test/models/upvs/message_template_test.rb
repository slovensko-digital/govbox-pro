# == Schema Information
#
# Table name: message_templates
#
#  id         :bigint           not null, primary key
#  content    :text             not null
#  metadata   :jsonb
#  name       :string           not null
#  system     :boolean          default(FALSE), not null
#  type       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  tenant_id  :bigint
#
require "test_helper"

class Upvs::MessageTemplateTest < ActiveSupport::TestCase
  test 'builds XML form for message draft' do
    message_template = upvs_message_templates(:general_agenda)

    message_draft = message_template.create_message(author: users(:basic), box: boxes(:ssd_main), recipient_name: 'Test OVM', recipient_uri: 'ico://sk/12345678')

    message_draft.metadata['data'] = {
      Predmet: 'Odpoved',
      Text: 'Odpoved k rozhodnutiu...'
    }
    message_draft.save

    message_template.build_message_from_template(message_draft)

    assert_equal '<GeneralAgenda xmlns="http://schemas.gov.sk/form/App.GeneralAgenda/1.9"> <subject>Odpoved</subject> <text>Odpoved k rozhodnutiu...</text> </GeneralAgenda>', message_draft.form_object.content
  end
end
