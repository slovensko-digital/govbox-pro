class EnableUpvsFeatureFlagForTenantsWithUpvsInbox < ActiveRecord::Migration[7.1]
  def up
    Tenant
      .joins(:boxes)
      .merge(Upvs::Box.all)
      .distinct
      .find_each do |tenant|
      next if tenant.feature_enabled?(:upvs)

      tenant.enable_feature(:upvs, force: true)
    end
  end
end
