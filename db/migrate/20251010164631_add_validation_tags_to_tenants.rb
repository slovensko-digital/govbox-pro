class AddValidationTagsToTenants < ActiveRecord::Migration[7.1]
  def change
    Tenant.find_each do |tenant|
      tenant.tags.find_or_create_by!(
        name: 'Chybné údaje',
        type: 'ValidationErrorTag'
      ).tap do |tag|
        tag.color = 'red'
        tag.icon = 'exclamation-triangle'
        tag.save!
      end

      tenant.tags.find_or_create_by!(
        name: 'Upozornenia',
        type: 'ValidationWarningTag'
      ).tap do |tag|
        tag.color = 'orange'
        tag.icon = 'exclamation-triangle'
        tag.save!
      end
    end
  end
end
