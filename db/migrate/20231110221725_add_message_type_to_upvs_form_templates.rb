class AddMessageTypeToUpvsFormTemplates < ActiveRecord::Migration[7.0]
  def up
    add_column :upvs_form_templates, :message_type, :string

    Upvs::FormTemplate.where(identifier: "App.GeneralAgenda").update_all(message_type: 'App.GeneralAgenda')
    Upvs::FormTemplate.where(identifier: '00166073.RESS_Exekucne_konanie_Navrh_na_vykonanie_exekucie.sk').update_all(message_type: '00166073.RESS_Exekucne_konanie_Navrh_na_vykonanie_exekucie.sk')

    change_column :upvs_form_templates, :message_type, :string, null: false
  end
end
