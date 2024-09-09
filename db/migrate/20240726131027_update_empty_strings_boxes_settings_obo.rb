class UpdateEmptyStringsBoxesSettingsObo < ActiveRecord::Migration[7.1]
  def up
    Upvs::Box.find_each do |box|
      box.normalize_attribute(:settings)
      box.save
    end
  end
end
