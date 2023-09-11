class Searchable::MessageThreadQuery
  def self.remove_label_from_text(text, match)
    text.gsub("#{match[0]}:(#{match[1]})", '')
  end

  def self.parse(query)
    filter_labels = []
    filter_out_labels = []

    with_text = query

    query.to_s.scan(/(-?label):\(([^)]+)\)/).each do |match|
      raise "unexpected label case" if match.length != 2

      if match[0] == "label"
        filter_labels << match[1]

        with_text = remove_label_from_text(with_text, match)
      end

      if match[0] == "-label"
        filter_out_labels << match[1]

        with_text = remove_label_from_text(with_text, match)
      end
    end

    {
      fulltext: with_text.gsub(/\s+/, ' ').strip,
      filter_labels: filter_labels,
      filter_out_labels: filter_out_labels
    }
  end

  def self.labels_to_ids(parsed_query, no_custom_tags: false)
    filter_tag_ids = label_names_to_tag_ids(parsed_query[:filter_labels])
    filter_out_tag_ids = label_names_to_tag_ids(parsed_query[:filter_out_labels])

    filter_out_tag_ids.concat(treads_ids_without_custom_tags()) if no_custom_tags

    result = {}

    if parsed_query[:filter_labels].present?
      if parsed_query[:filter_labels].length == filter_tag_ids.length
        result[:filter_tag_ids] = filter_tag_ids
      else
        result[:filter_tag_ids] = :missing_tag
      end
    end

    result[:filter_out_tag_ids] = filter_out_tag_ids if filter_out_tag_ids.present?
    result[:fulltext] = parsed_query[:fulltext] if parsed_query[:fulltext].present?

    result
  end

  def self.label_names_to_tag_ids(label_names)
    Tag.where(name: label_names).pluck(:id)
  end

  def self.treads_ids_without_custom_tags()
    Tag.where('tags.name not like ?', 'slovensko.sk:%').pluck(:id)
  end
end
