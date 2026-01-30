# frozen_string_literal: true

class Searchable::MessageThreadQuery
  PREFIX_SEARCH_REGEXP = /^\S{4,}\*$/

  def self.parse(query, user_tag_name: nil)
    filter_labels = []
    filter_out_labels = []

    with_text = query.to_s

    with_text.scan(/(-?(?:label|author)):(\(([^)]+)\)|([^ ]+)|\*)/).each do |match|
      key = match[0] # "label", "-label", "author"
      value = [match[2], match[3]].find(&:presence)

      case key
      when "label"
        filter_labels << value
        with_text = with_text.gsub("#{key}:#{match[1]}", "")
      when "-label"
        filter_out_labels << value
        with_text = with_text.gsub("#{key}:#{match[1]}", "")
      when "author"
        if value == "me" && user_tag_name
          filter_labels << user_tag_name
          with_text = with_text.gsub("#{key}:#{match[1]}", "")
        end
      end
    end

    with_text = with_text.gsub(/\s+/, " ").strip

    {
      fulltext: with_text,
      prefix_search: with_text.match?(PREFIX_SEARCH_REGEXP),
      filter_labels: filter_labels,
      filter_out_labels: filter_out_labels,
    }
  end

  def self.labels_to_ids(parsed_query, tenant:)
    fulltext, prefix_search, filter_labels, filter_out_labels =
      parsed_query.fetch_values(:fulltext, :prefix_search, :filter_labels, :filter_out_labels)

    # TODO maybe with one query
    found_all, filter_tag_ids = label_names_to_tag_ids(tenant, filter_labels)
    _, filter_out_tag_ids = label_names_to_tag_ids(tenant, filter_out_labels)

    result = {}

    if filter_labels.present?
      if found_all
        result[:filter_tag_ids] = filter_tag_ids
      else
        result[:filter_tag_ids] = :missing_tag
      end
    end

    result[:filter_out_tag_ids] = filter_out_tag_ids if filter_out_tag_ids.present?
    result[:fulltext] = fulltext if fulltext.present?
    result[:prefix_search] = prefix_search

    result
  end

  def self.label_names_to_tag_ids(tenant, label_names)
    if label_names.find { |name| name == "*" }.present?
      [true, tenant.tags.visible.pluck(:id)]
    else
      ids = tenant.tags.where(name: label_names).pluck(:id)
      [ids.length == label_names.length, ids]
    end
  end
end
