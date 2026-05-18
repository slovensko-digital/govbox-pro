class MakeEmailOptionalAndEnforceSamlOrEmailOnUsers < ActiveRecord::Migration[7.1]
  def up
    change_column_null :users, :email, true

    add_check_constraint :users,
                         "email IS NOT NULL OR saml_identifier IS NOT NULL",
                         name: "email_or_saml_identifier_required"
  end
end

