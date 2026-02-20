class AddProblemTags < ActiveRecord::Migration[7.1]
  def up
    Tenant.find_each do |tenant|
      tenant.tags.find_or_create_by!(
        name: 'Chyba pri odoslaní',
        type: 'SubmissionErrorTag'
      )
    end
  end
end
