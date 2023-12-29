module SigningTagsHelper
  def self.sort_tags(tags)
    tags.to_a.sort_by { |tag| [tag_type_to_order(tag), tag.name] }
  end

  def self.tag_type_to_order(tag)
    case tag
      when SignatureRequestedTag
        "1"
      when SignedTag
        "1"
      when SignatureRequestedFromTag
        "2"
      when SignedByTag
        "3"
      when SignedExternallyTag
        "5"
      else
        "4"
    end
  end
end
