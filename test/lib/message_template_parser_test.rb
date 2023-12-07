# frozen_string_literal: true

require "test_helper"

class MessageTemplateParserTest < ActiveSupport::TestCase
  test "should parse message reply template placeholder, its name, empty default value and type" do
    template = upvs_message_templates(:message_reply)
    template_items = MessageTemplateParser.parse_template_placeholders(template)

    assert_equal template_items.count, 2

    assert_equal '{{ Predmet:text_field }}', template_items.first[:placeholder]
    assert_equal 'Predmet', template_items.first[:name]
    assert_equal false, template_items.first[:required]
    assert_equal nil, template_items.first[:default_value]
    assert_equal 'text_field', template_items.first[:type]

    assert_equal '{{ Text:text_area }}', template_items.second[:placeholder]
    assert_equal 'Text', template_items.second[:name]
    assert_equal false, template_items.second[:required]
    assert_equal nil, template_items.second[:default_value]
    assert_equal 'text_area', template_items.second[:type]
  end

  test "should parse template placeholder, its name, default value and type" do
    template = upvs_message_templates(:ssd_crac_template)
    template_items = MessageTemplateParser.parse_template_placeholders(template)

    assert_equal template_items.count, 7

    assert_equal '{{ IČO*:text_field }}', template_items.first[:placeholder]
    assert_equal 'IČO', template_items.first[:name]
    assert_equal true, template_items.first[:required]
    assert_equal nil, template_items.first[:default_value]
    assert_equal 'text_field', template_items.first[:type]

    assert_equal '{{ Kontaktná osoba*:text_field:"Ján Suchal" }}', template_items.second[:placeholder]
    assert_equal 'Kontaktná osoba', template_items.second[:name]
    assert_equal true, template_items.second[:required]
    assert_equal 'Ján Suchal', template_items.second[:default_value]
    assert_equal 'text_field', template_items.second[:type]

    assert_equal '{{ Email*:text_field:"jan.suchal@test.sk" }}', template_items.third[:placeholder]
    assert_equal 'Email', template_items.third[:name]
    assert_equal true, template_items.third[:required]
    assert_equal 'jan.suchal@test.sk', template_items.third[:default_value]
    assert_equal 'text_field', template_items.third[:type]

    assert_equal '{{ Telefón*:text_field:"+4190000000" }}', template_items.fourth[:placeholder]
    assert_equal 'Telefón', template_items.fourth[:name]
    assert_equal true, template_items.fourth[:required]
    assert_equal '+4190000000', template_items.fourth[:default_value]
    assert_equal 'text_field', template_items.fourth[:type]

    assert_equal '{{ Názov prostriedku:text_field:"IRVIN" }}', template_items.fifth[:placeholder]
    assert_equal 'Názov prostriedku', template_items.fifth[:name]
    assert_equal false, template_items.fifth[:required]
    assert_equal 'IRVIN', template_items.fifth[:default_value]
    assert_equal 'text_field', template_items.fifth[:type]

    assert_equal '{{ Dátum začiatku platnosti*:date_field }}', template_items[5][:placeholder]
    assert_equal 'Dátum začiatku platnosti', template_items[5][:name]
    assert_equal true, template_items[5][:required]
    assert_equal nil, template_items[5][:default_value]
    assert_equal 'date_field', template_items[5][:type]

    assert_equal '{{ Digitálny odtlačok*:text_field }}', template_items[6][:placeholder]
    assert_equal 'Digitálny odtlačok', template_items[6][:name]
    assert_equal true, template_items[6][:required]
    assert_equal nil, template_items[6][:default_value]
    assert_equal 'text_field', template_items[6][:type]

  end
end
