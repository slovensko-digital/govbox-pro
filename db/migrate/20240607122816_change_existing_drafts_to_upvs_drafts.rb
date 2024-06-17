class ChangeExistingDraftsToUpvsDrafts < ActiveRecord::Migration[7.1]
  def change
    MessageDraft.update_all(type: 'Upvs::MessageDraft')
  end
end
