class DeleteDownloadedUpvsDrafts < ActiveRecord::Migration[7.0]
  def change
    Govbox::Folder.where("name ILIKE ?", "drafts%").find_each do |draft_folder|
      draft_folder.messages.destroy_all
    end

    Tag.where(name: "slovensko.sk:Drafts").find_each do |sk_sk_drafts_tag|
      sk_sk_drafts_tag.messages.find_each do |draft_message|
        draft_message.destroy!
        draft_message.thread.destroy! if draft_message.thread.messages.none?
      end
    end
  end
end
