class RemoveExtraSignatureTags < ActiveRecord::Migration[7.1]
  def up
    MessageThread.find_each do |message_thread|
      message_thread.unassign_tag(message_thread.tenant.signature_requested_tag!) unless message_thread.tags.reload.where(type: SignatureRequestedFromTag.to_s).any?
      message_thread.unassign_tag(message_thread.tenant.signed_tag!) unless message_thread.tags.reload.where(type: SignedByTag.to_s).any?
    end
  end
end
