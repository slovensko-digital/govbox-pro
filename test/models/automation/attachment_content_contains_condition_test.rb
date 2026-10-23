require 'test_helper'

class Automation::AttachmentContentContainsConditionTest < ActiveSupport::TestCase
  setup do
    @matching_pdf = File.binread("test/fixtures/files/test_string.pdf")
    @not_matching_pdf = File.binread("test/fixtures/files/lorem_ipsum.pdf")
  end

  test 'is satisfied when PDF attachment content matches' do
    thing = thing_with(pdf_object(@matching_pdf))

    assert condition('Test\s*string').satisfied?(thing)
  end

  test 'is not satisfied when PDF attachment content does not match' do
    thing = thing_with(pdf_object(@not_matching_pdf))

    assert_not condition('Test\s*string').satisfied?(thing)
  end

  test 'is satisfied when XML attachment content matches' do
    object = MessageObject.new(mimetype: 'application/xml', message_object_datum: MessageObjectDatum.new(blob: '<doc><text>úspešne spracovaná</text></doc>'))

    assert condition('úspešne spracovaná').satisfied?(thing_with(object))
  end

  test 'is satisfied when nested PDF object content matches' do
    object = MessageObject.new(mimetype: 'application/vnd.etsi.asic-e+zip')
    object.nested_message_objects.build(name: 'test.pdf', mimetype: Utils::PDF_MIMETYPE, content: @matching_pdf)

    assert condition('Test\s*string').satisfied?(thing_with(object))
  end

  test 'is not satisfied and does not parse objects that are neither PDF nor XML' do
    object = MessageObject.new(mimetype: 'text/plain', message_object_datum: MessageObjectDatum.new(blob: 'Test string'))

    PDF::Reader.stub(:open, ->(*) { flunk 'PDF should not be parsed' }) do
      assert_not condition('Test\s*string').satisfied?(thing_with(object))
    end
  end

  test 'parses each PDF only once when evaluated by multiple conditions' do
    thing = thing_with(pdf_object(@not_matching_pdf), pdf_object(@matching_pdf))
    conditions = Array.new(5) { |i| condition("not present #{i}") } + [condition('Test\s*string')]

    parse_count = 0
    original_open = PDF::Reader.method(:open)
    counting_open = lambda do |*args, &block|
      parse_count += 1
      original_open.call(*args, &block)
    end

    PDF::Reader.stub(:open, counting_open) do
      assert_equal [false] * 5 + [true], conditions.map { |c| c.satisfied?(thing) }
    end

    assert_equal 2, parse_count
  end

  private

  def condition(value)
    Automation::AttachmentContentContainsCondition.new(value: value)
  end

  def pdf_object(content)
    MessageObject.new(mimetype: Utils::PDF_MIMETYPE, message_object_datum: MessageObjectDatum.new(blob: content))
  end

  def thing_with(*objects)
    Struct.new(:objects).new(objects)
  end
end
