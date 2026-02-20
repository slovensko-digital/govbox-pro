class ChangeSubmissionErrorTagsToProblemTags < ActiveRecord::Migration[7.1]
  def up
    SubmissionErrorTag.update_all(type: 'ProblemTag')
  end
end
