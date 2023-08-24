class RenameDraftsImportsToMessageDraftsImports < ActiveRecord::Migration[7.0]
  def up
    rename_table :drafts_imports, :message_drafts_imports
  end
end
