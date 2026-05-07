class MakeEmailOptionalAndEnforceSamlOrEmailOnUsers < ActiveRecord::Migration[7.1]
  def up
    change_column_null :users, :email, true

    execute <<~SQL.squish
      ALTER TABLE users
        ADD CONSTRAINT email_or_saml_identifier_required
        CHECK (email IS NOT NULL OR saml_identifier IS NOT NULL);
    SQL
  end

  def down
    execute <<~SQL.squish
      ALTER TABLE users
        DROP CONSTRAINT email_or_saml_identifier_required;
    SQL

    change_column_null :users, :email, false
  end
end

