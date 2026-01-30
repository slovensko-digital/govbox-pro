require "test_helper"

class Searchable::MessageThreadQueryTest < ActiveSupport::TestCase
  setup do
    Current.user = users(:basic)
  end

  teardown do
    Current.user = nil
  end

  test "parser empty" do
    assert_equal Searchable::MessageThreadQuery.parse('', user_tag_name: Current.user.author_tag&.name), {
      fulltext: '',
      prefix_search: false,
      filter_labels: [],
      filter_out_labels: []
    }

    assert_equal Searchable::MessageThreadQuery.parse(nil, user_tag_name: Current.user.author_tag&.name), {
      fulltext: '',
      prefix_search: false,
      filter_labels: [],
      filter_out_labels: []
    }
  end

  test "parser only include tag" do
    assert_equal Searchable::MessageThreadQuery.parse('label:(tag one/with something)', user_tag_name: Current.user.author_tag&.name), {
      fulltext: '',
      prefix_search: false,
      filter_labels: ['tag one/with something'],
      filter_out_labels: []
    }
  end

  test "parser only exclude tag" do
    assert_equal Searchable::MessageThreadQuery.parse('-label:(without)', user_tag_name: Current.user.author_tag&.name), {
      fulltext: '',
      prefix_search: false,
      filter_labels: [],
      filter_out_labels: ['without']
    }
  end

  test "parser everything" do
    query = 'label:(tag one/with something) hello label:(tag two) world -label:(without this tag) ending'
    assert_equal Searchable::MessageThreadQuery.parse(query, user_tag_name: Current.user.author_tag&.name), {
      fulltext: 'hello world ending',
      prefix_search: false,
      filter_labels: ['tag one/with something', 'tag two'],
      filter_out_labels: ['without this tag']
    }
  end

  test "parser no visible tags" do
    query = 'something -label:* else'
    assert_equal Searchable::MessageThreadQuery.parse(query, user_tag_name: Current.user.author_tag&.name), {
      fulltext: 'something else',
      prefix_search: false,
      filter_labels: [],
      filter_out_labels: ["*"]
    }
  end

  test "parser no visible tags with other labels to filter out" do
    query = 'something -label:* else -label:two'
    assert_equal Searchable::MessageThreadQuery.parse(query, user_tag_name: Current.user.author_tag&.name), {
      fulltext: 'something else',
      prefix_search: false,
      filter_labels: [],
      filter_out_labels: ["*", "two"]
    }
  end

  test "parser with prefix search" do
    query = 'someth* -label:*'
    assert_equal Searchable::MessageThreadQuery.parse(query, user_tag_name: Current.user.author_tag&.name), {
      fulltext: 'someth*',
      prefix_search: true,
      filter_labels: [],
      filter_out_labels: ["*"]
    }
  end

  test "parser without prefix search for multiple words" do
    query = 'tell me someth*'
    assert_equal Searchable::MessageThreadQuery.parse(query, user_tag_name: Current.user.author_tag&.name), {
      fulltext: 'tell me someth*',
      prefix_search: false,
      filter_labels: [],
      filter_out_labels: []
    }
  end

  test "parser author:me" do
    expected_author_tag = Current.user.author_tag&.name

    assert_equal Searchable::MessageThreadQuery.parse('author:me NASES', user_tag_name: expected_author_tag), {
      fulltext: 'NASES',
      prefix_search: false,
      filter_labels: [expected_author_tag],
      filter_out_labels: []
    }
  end

  test "parser author:XYZ treated as fulltext" do
    assert_equal Searchable::MessageThreadQuery.parse('author:jano NASES', user_tag_name: Current.user.author_tag&.name), {
      fulltext: 'author:jano NASES',
      prefix_search: false,
      filter_labels: [],
      filter_out_labels: []
    }
  end

  test "parser mixed author:me and tag" do
    expected_author_tag = Current.user.author_tag&.name

    query = 'label:(NASES) author:me žiadosť'
    assert_equal Searchable::MessageThreadQuery.parse(query, user_tag_name: Current.user.author_tag&.name), {
      fulltext: 'žiadosť',
      prefix_search: false,
      filter_labels: ['NASES', expected_author_tag],
      filter_out_labels: []
    }
  end

  test "parser mixed author:XYZ and tag" do
    query = 'label:(NASES) author:jano žiadosť'
    assert_equal Searchable::MessageThreadQuery.parse(query, user_tag_name: Current.user.author_tag&.name), {
      fulltext: 'author:jano žiadosť',
      prefix_search: false,
      filter_labels: ['NASES'],
      filter_out_labels: []
    }
  end
end
