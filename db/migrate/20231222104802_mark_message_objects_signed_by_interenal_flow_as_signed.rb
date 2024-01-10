class MarkMessageObjectsSignedByInterenalFlowAsSigned < ActiveRecord::Migration[7.1]
  def up
    MessageObject.joins(:tags).where(is_signed: false, tags: { type: SignedByTag.to_s }).update_all(is_signed: true)
  end

  def down
  end
end
