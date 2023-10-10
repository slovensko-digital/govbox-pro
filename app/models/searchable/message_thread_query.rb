# frozen_string_literal: true

class Searchable::MessageThreadQuery
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

    {
      fulltext: with_text.gsub(/\s+/, ' ').strip,
      filter_labels: filter_labels,
      filter_out_labels: filter_out_labels,
    }
  end

  def self.labels_to_ids(parsed_query, tenant_id:)
    fulltext, filter_labels, filter_out_labels =
      parsed_query.fetch_values(:fulltext, :filter_labels, :filter_out_labels)

    found_all, filter_tag_ids = label_names_to_tag_ids(tenant_id, filter_labels)
    _, filter_out_tag_ids = label_names_to_tag_ids(tenant_id, filter_out_labels)

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

    result
  end

  def self.label_names_to_tag_ids(tenant_id, label_names)
    if label_names.find { |name| name == "*" }.present?
      [true, Tag.where(tenant_id: tenant_id, visible: true).pluck(:id)]
    else
      ids = Tag.where(tenant_id: tenant_id, name: label_names).pluck(:id)
      [ids.length == label_names.length, ids]
    end
  end
end
