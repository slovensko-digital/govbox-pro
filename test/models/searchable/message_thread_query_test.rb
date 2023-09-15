require "test_helper"

class Searchable::MessageThreadQueryTest < ActiveSupport::TestCase
  test "parser empty" do
    assert_equal Searchable::MessageThreadQuery.parse(''), {
      fulltext: '',
      filter_labels: [],
      filter_out_labels: []
    }

    assert_equal Searchable::MessageThreadQuery.parse(nil), {
      fulltext: '',
      filter_labels: [],
      filter_out_labels: []
    }
  end

  test "parser only include tag" do
    assert_equal Searchable::MessageThreadQuery.parse('label:(tag one/with something)'), {
      fulltext: '',
      filter_labels: ['tag one/with something'],
      filter_out_labels: []
    }
  end

  test "parser only exclude tag" do
    assert_equal Searchable::MessageThreadQuery.parse('-label:(without)'), {
      fulltext: '',
      filter_labels: [],
      filter_out_labels: ['without']
    }
  end

  test "parser everything" do
    query = 'label:(tag one/with something) hello label:(tag two) world -label:(without this tag) ending'
    assert_equal Searchable::MessageThreadQuery.parse(query), {
      fulltext: 'hello world ending',
      filter_labels: ['tag one/with something', 'tag two'],
      filter_out_labels: ['without this tag']
    }
  end
end
