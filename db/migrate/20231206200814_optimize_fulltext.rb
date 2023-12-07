class OptimizeFulltext < ActiveRecord::Migration[7.1]
  def change
    add_index :searchable_message_threads, %[(((to_tsvector('simple'::regconfig, COALESCE(title, ''::text)) || to_tsvector('simple'::regconfig, COALESCE(content, ''::text))) || to_tsvector('simple'::regconfig, COALESCE((note)::text, ''::text))) || to_tsvector('simple'::regconfig, COALESCE(tag_names, ''::text)))], using: :gin, name: :idx_searchable_message_threads_fulltext
    add_index :searchable_message_threads, ["id", "box_id", "last_message_delivered_at"], unique: true
  end
end
