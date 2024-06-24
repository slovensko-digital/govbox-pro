class CreateTagFiltersFromTags < ActiveRecord::Migration[7.1]
  def up
    Tenant.find_each do |tenant|
      tenant.tags.visible.find_each do |tag|
        TagFilter.create!(
          tenant:,
          author: tag.owner,
          name: tag.name,
          tag:,
        )
      end

      tenant.everything_tag.tap do |tag|
        EverythingFilter.create!(
          tenant:,
          author: tag.owner,
          name: tag.name,
          tag:,
        ).tap do |filter|
          filter.move_to_top
        end
      end
    end
  end

  def down
    TagFilter.destroy_all
  end
end
