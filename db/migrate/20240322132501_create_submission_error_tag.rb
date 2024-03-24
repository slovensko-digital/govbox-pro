class CreateSubmissionErrorTag < ActiveRecord::Migration[7.1]
  def up
    Tenant.find_each do |tenant|
      tenant.tags.find_or_create_by!(
        name: 'Chyba odoslania',
        type: 'SubmissionErrorTag'
      )
    end
  end
end
