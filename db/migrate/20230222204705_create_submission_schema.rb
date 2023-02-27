class CreateSubmissionSchema < ActiveRecord::Migration[6.1]
  def up
    execute 'CREATE SCHEMA submission'
  end

  def down
    execute 'DROP SCHEMA submission'
  end
end
