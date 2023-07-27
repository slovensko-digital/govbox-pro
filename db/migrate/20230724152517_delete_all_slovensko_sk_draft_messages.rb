class DeleteAllSlovenskoSkDraftMessages < ActiveRecord::Migration[7.0]
  def change
    Message.joins(:tags).where(tags: { name: 'slovensko.sk:Drafts' }).find_each do |message|
      thread = message.thread
      if thread.messages.count == 1
        message.destroy
        thread.destroy
      else
        message.destroy
      end
    end
  end
end
