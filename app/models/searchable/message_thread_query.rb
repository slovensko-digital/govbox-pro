# frozen_string_literal: true

class Searchable::MessageThreadQuery
  WITHOUT_ALL_VISIBLE_LABELS = "-label:*"

  def self.remove_label_from_text(text, match)
    text.gsub("#{match[0]}:(#{match[1]})", "")
  end

  def self.parse(query)
    filter_labels = []
    filter_out_labels = []
    filter_out_all_visible_labels = false

    with_text = query.to_s

    query.to_s.scan(/(-?label):\(([^)]+)\)|(-label:\*)/).each do |match|
      raise "unexpected label case" if match.length != 3

      if match[0] == "label"
        filter_labels << match[1]

        with_text = remove_label_from_text(with_text, match)
      elsif match[0] == "-label"
        filter_out_labels << match[1]

        with_text = remove_label_from_text(with_text, match)
      elsif match[2] == WITHOUT_ALL_VISIBLE_LABELS
        filter_out_all_visible_labels = true
        with_text = with_text.gsub(WITHOUT_ALL_VISIBLE_LABELS, "")
      end
    end

    {
      fulltext: with_text.gsub(/\s+/, ' ').strip,
      filter_labels: filter_labels,
      filter_out_labels: filter_out_labels,
      filter_out_all_visible_labels: filter_out_all_visible_labels,
    }
  end

  def self.labels_to_ids(parsed_query, tenant_id:)
    fulltext, filter_labels, filter_out_labels, filter_out_all_visible_labels =
      parsed_query.fetch_values(:fulltext, :filter_labels, :filter_out_labels, :filter_out_all_visible_labels)

    filter_tag_ids = label_names_to_tag_ids(tenant_id, filter_labels)
    filter_out_tag_ids = label_names_to_tag_ids(tenant_id, filter_out_labels)

    filter_out_tag_ids.concat(visible_tag_ids(tenant_id)) if filter_out_all_visible_labels

    result = {}

    if filter_labels.present?
      if filter_labels.length == filter_tag_ids.length
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
    Tag.where(tenant_id: tenant_id, name: label_names).pluck(:id)
  end

  def self.visible_tag_ids(tenant_id)
    Tag.where(tenant_id: tenant_id, visible: true).pluck(:id)
  end
end
