class AddUnprocessableTagToTenants < ActiveRecord::Migration[7.1]
  def change
    Tenant.find_each do |tenant|
      tenant.tags.find_or_create_by!(
        name: 'Chybné',
        type: 'UnprocessableTag'
      ).tap do |tag|
        tag.color = 'red'
        tag.icon = 'exclamation-triangle'
        tag.save!
      end
    end
  end
end

