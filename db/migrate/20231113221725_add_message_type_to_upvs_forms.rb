class AddMessageTypeToUpvsForms < ActiveRecord::Migration[7.0]
  def up
    add_column :upvs_forms, :message_type, :string

    Upvs::Form.where(identifier: 'App.GeneralAgenda').update_all(message_type: 'App.GeneralAgenda')
    Upvs::Form.where(identifier: '00166073.RESS_Exekucne_konanie_Navrh_na_vykonanie_exekucie.sk').update_all(message_type: '00166073.RESS_Exekucne_konanie_Navrh_na_vykonanie_exekucie.sk')

    change_column :upvs_forms, :message_type, :string, null: false
    add_index :upvs_forms, [:identifier, :version, :message_type], unique: true, name: :index_forms_on_identifier_version_message_type
  end
end
