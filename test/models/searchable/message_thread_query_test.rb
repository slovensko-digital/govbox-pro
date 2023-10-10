require "test_helper"

class Searchable::MessageThreadQueryTest < ActiveSupport::TestCase
  test "parser empty" do
    assert_equal Searchable::MessageThreadQuery.parse(''), {
      fulltext: '',
      filter_labels: [],
      filter_out_labels: [],
      filter_out_all_visible_labels: false
    }

    assert_equal Searchable::MessageThreadQuery.parse(nil), {
      fulltext: '',
      filter_labels: [],
      filter_out_labels: [],
      filter_out_all_visible_labels: false
    }
  end

  test "parser only include tag" do
    assert_equal Searchable::MessageThreadQuery.parse('label:(tag one/with something)'), {
      fulltext: '',
      filter_labels: ['tag one/with something'],
      filter_out_labels: [],
      filter_out_all_visible_labels: false
    }
  end

  test "parser only exclude tag" do
    assert_equal Searchable::MessageThreadQuery.parse('-label:(without)'), {
      fulltext: '',
      filter_labels: [],
      filter_out_labels: ['without'],
      filter_out_all_visible_labels: false
    }
  end

  test "parser everything" do
    query = 'label:(tag one/with something) hello label:(tag two) world -label:(without this tag) ending'
    assert_equal Searchable::MessageThreadQuery.parse(query), {
      fulltext: 'hello world ending',
      filter_labels: ['tag one/with something', 'tag two'],
      filter_out_labels: ['without this tag'],
      filter_out_all_visible_labels: false
    }
  end

  test "parser no visible tags" do
    query = 'something -label:* else'
    assert_equal Searchable::MessageThreadQuery.parse(query), {
      fulltext: 'something else',
      filter_labels: [],
      filter_out_labels: [],
      filter_out_all_visible_labels: true
    }
  end
end
