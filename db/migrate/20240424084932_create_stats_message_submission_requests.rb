class CreateStatsMessageSubmissionRequests < ActiveRecord::Migration[7.1]
  def change
    create_table :stats_message_submission_requests do |t|
      t.belongs_to :box, null: false, foreign_key: true
      t.string :request_url
      t.integer :response_status
      t.boolean :bulk
      t.timestamps
    end
  end
end
