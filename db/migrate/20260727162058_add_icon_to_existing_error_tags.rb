class AddIconToExistingErrorTags < ActiveRecord::Migration[7.1]
  def up
    Tag.where(type: %w[ProblemTag SubmissionErrorTag])
       .where(icon: [nil, ''])
       .update_all(icon: 'exclamation-triangle', color: 'red')
  end
end
