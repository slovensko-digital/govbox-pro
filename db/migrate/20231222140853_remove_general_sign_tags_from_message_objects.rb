class RemoveGeneralSignTagsFromMessageObjects < ActiveRecord::Migration[7.1]
  def up
    MessageObjectsTag.joins(:tag).where(tags: { type: [SignatureRequestedTag, SignedTag].map(&:to_s) }).destroy_all
  end

  def down
  end
end
