class ColorizeAndIconizeSignatureTags < ActiveRecord::Migration[7.1]
  def up
    SignatureRequestedTag.update_all(color: "yellow", icon: "pencil")
    SignatureRequestedFromTag.update_all(color: "yellow", icon: "pencil")
    SignedTag.update_all(color: "green", icon: "fingerprint")
    SignedByTag.update_all(color: "green", icon: "fingerprint")
  end

  def down
    SignatureRequestedTag.update_all(color: nil, icon: nil)
    SignatureRequestedFromTag.update_all(color: nil, icon: nil)
    SignedTag.update_all(color: nil, icon: nil)
    SignedByTag.update_all(color: nil, icon: nil)
  end
end
