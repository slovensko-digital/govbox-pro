class AddUniqueNameIndexToTags < ActiveRecord::Migration[7.0]
  def up
    Tag.connection.select_all(
      "select tenant_id, ARRAY_AGG(id) AS ids from tags GROUP BY (tenant_id, LOWER(name)) HAVING COUNT(*) > 1;"
    ).cast_values.each do |row|
      tenant_id, ids = row

      tags = Tag.where(tenant_id: tenant_id).find(ids)

      main_tag = tags[0]

      tags[1..-1].each do |other_tag|
        MessagesTag.where(tag_id: other_tag).map do |mt|
          mt.tag_id = main_tag.id
          mt.save!
        end

        MessageThreadsTag.where(tag_id: other_tag).map do |mtt|
          mtt.tag_id = main_tag.id
          mtt.save!
        end

        TagGroup.where(tag_id: other_tag).map do |tg|
          tg.tag_id = main_tag.id
          tg.save!
        end

        other_tag.destroy
      end
    end

    execute "CREATE UNIQUE INDEX index_tags_on_tenant_id_and_lowercase_name ON tags USING btree (tenant_id, lower(name));"
  end

  def down
    remove_index :tags, name: "index_tags_on_tenant_id_and_lowercase_name"
  end
end
