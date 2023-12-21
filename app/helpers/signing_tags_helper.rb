module SigningTagsHelper
  def self.sort_tags(tags)
    tags.to_a.sort_by { |tag| [tag_type_to_order(tag), tag.name] }
  end

  def self.tag_type_to_order(tag)
    case tag.class
      when SignatureRequestedTag
        "1"
      when SignatureRequestedFromTag
        "2"
      else
        "3"
    end
  end

  def self.signed_externally
    Tag.new(name: "Externe podpísané", icon: "shield-check", color: "purple")
  end
end
