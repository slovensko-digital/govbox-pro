class AddDownloadableToUpvsForms < ActiveRecord::Migration[7.1]
  def change
    add_column :upvs_forms, :downloadable, :boolean, default: true

    Upvs::Form.where(identifier: ['ks_352538', 'ks_362431']).update_all(downloadable: false)
  end
end
