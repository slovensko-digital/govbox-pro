class TagFilterCatalog
  def self.sync!(tenant)
    tenant.with_lock do
      tenant.tags.order(:id).each { |tag| add!(tag) }
    end
  end

  def self.add!(tag)
    tag.tenant.with_lock do
      return if tag.tenant.filters.exists?(tag: tag)

      query = tag.is_a?(EverythingTag) ? "" : "label:(#{tag.name})"
      existing = tag.tenant.filters.common.find_by(query: query)
      if existing
        existing.update!(tag: tag)
      else
        tag.tenant.filters.create!(common: true, tag: tag, name: tag.name, query: query)
      end
    end
  end
end
