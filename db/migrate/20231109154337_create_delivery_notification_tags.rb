class CreateDeliveryNotificationTags < ActiveRecord::Migration[7.0]
  def change
    Tenant.find_each do |tenant|
      tenant.tags.create!(
        name: 'Na prevzatie',
        system_name: 'DeliveryNotifications',
        external: false,
        visible: true
      )
    end
  end
end
