# frozen_string_literal: true

require "test_helper"

class MessageTemplateParserTest < ActiveSupport::TestCase
  test "should parse message reply template placeholder, its name, empty default value and type" do
    template = upvs_message_templates(:message_reply)
    template_items = MessageTemplateParser.parse_template_placeholders(template)

    assert_equal template_items.count, 2

    assert_equal template_items.first[:placeholder], "{{Predmet::text_field}}"
    assert_equal template_items.first[:name], "Predmet"
    assert_equal template_items.first[:default_value], nil
    assert_equal template_items.first[:type], "text_field"

    assert_equal template_items.second[:placeholder], "{{Text::text_area}}"
    assert_equal template_items.second[:name], "Text"
    assert_equal template_items.second[:default_value], nil
    assert_equal template_items.second[:type], "text_area"
  end

  test "should parse template placeholder, its name, default value and type" do
    template = upvs_message_templates(:ssd_crac_template)
    template_items = MessageTemplateParser.parse_template_placeholders(template)

    assert_equal template_items.count, 7

    assert_equal template_items.first[:placeholder], "{{IČO::text_field}}"
    assert_equal template_items.first[:name], "IČO"
    assert_equal template_items.first[:default_value], nil
    assert_equal template_items.first[:type], "text_field"

    assert_equal template_items.second[:placeholder], "{{Kontaktná osoba:Ján Suchal:text_field}}"
    assert_equal template_items.second[:name], "Kontaktná osoba"
    assert_equal template_items.second[:default_value], "Ján Suchal"
    assert_equal template_items.second[:type], "text_field"

    assert_equal template_items.third[:placeholder], "{{Email:jan.suchal@test.sk:text_field}}"
    assert_equal template_items.third[:name], "Email"
    assert_equal template_items.third[:default_value], "jan.suchal@test.sk"
    assert_equal template_items.third[:type], "text_field"

    assert_equal template_items.fourth[:placeholder], "{{Telefón:+4190000000:text_field}}"
    assert_equal template_items.fourth[:name], "Telefón"
    assert_equal template_items.fourth[:default_value], "+4190000000"
    assert_equal template_items.fourth[:type], "text_field"

    assert_equal template_items.fifth[:placeholder], "{{Názov prostriedku:IRVIN:text_field}}"
    assert_equal template_items.fifth[:name], "Názov prostriedku"
    assert_equal template_items.fifth[:default_value], "IRVIN"
    assert_equal template_items.fifth[:type], "text_field"

    assert_equal template_items[5][:placeholder], "{{Dátum začiatku platnosti::date_field}}"
    assert_equal template_items[5][:name], "Dátum začiatku platnosti"
    assert_equal template_items[5][:default_value], nil
    assert_equal template_items[5][:type], "date_field"

    assert_equal template_items[6][:placeholder], "{{Digitálny odtlačok::text_field}}"
    assert_equal template_items[6][:name], "Digitálny odtlačok"
    assert_equal template_items[6][:default_value], nil
    assert_equal template_items[6][:type], "text_field"

  end
end
