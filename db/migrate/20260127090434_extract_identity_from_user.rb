class ExtractIdentityFromUser < ActiveRecord::Migration[7.1]
  def up
    create_table :identities do |t|
      t.string :email, null: false
      t.string :password_digest, null: false
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end

    add_index :identities, :email, unique: true

    User.find_each do |user|
      digest = user.read_attribute('password_digest')

      if digest.present?
        Identity.create!(
          user_id: user.id,
          email: user.email,
          password_digest: digest
        )
      end
    end

    remove_column :users, :password_digest
  end

  def down
    add_column :users, :password_digest, :string

    Identity.find_each do |identity|
      user = identity.user
      user&.update_column(:password_digest, identity.password_digest)
    end

    drop_table :identities
  end
end
