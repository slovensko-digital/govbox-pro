class UpdateEmptyStringsBoxesSettingsObo < ActiveRecord::Migration[7.1]
  def up
    Upvs::Box.find_each do |box|
      box.update(settings_obo: (box.settings_obo.present? ? box.settings_obo : nil))
    end
  end
end
