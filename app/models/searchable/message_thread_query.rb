# frozen_string_literal: true

class Searchable::MessageThreadQuery
  PREFIX_SEARCH_REGEXP = /^\S{4,}\*$/

  def self.parse(query)
    filter_labels = []
    filter_out_labels = []

    with_text = query.to_s

    query.to_s.scan(/(-?label):(\(([^)]+)\)|([^ ]+)|\*)/).each do |match|
      raise "unexpected label case" if match.length != 4

      label_name = [match[2], match[3]].find(&:presence)

      if match[0] == "label"
        filter_labels << label_name
      elsif match[0] == "-label"
        filter_out_labels << label_name
      end

      with_text = with_text.gsub("#{match[0]}:#{match[1]}", "")
    end

    with_text = with_text.gsub(/\s+/, ' ').strip

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
