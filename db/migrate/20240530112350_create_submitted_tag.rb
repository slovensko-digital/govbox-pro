class CreateSubmittedTag < ActiveRecord::Migration[7.1]
  def up
    Tenant.find_each do |tenant|
      tenant.tags.find_or_create_by!(
        name: 'Odoslané na spracovanie',
        type: 'SubmittedTag'
      )
    end
  end
end
