class DeleteAllSlovenskoSkDraftMessages < ActiveRecord::Migration[7.0]
  def change
    Message.joins(:tags).where(tags: { name: 'slovensko.sk:Drafts' }).find_each do |message|
      thread = message.thread
      message.destroy
      thread.destroy unless thread.messages.any?
    end
  end
end
