class AddExternalToTags < ActiveRecord::Migration[7.0]
  def change
    add_column :tags, :external, :boolean, default: false
    Tag.all.each do |tag|
      tag.external = (tag.name.match? '^slovensko.sk')
      tag.save
    end
  end
end
