class AddTemplateToUpvsFormTemplates < ActiveRecord::Migration[7.0]
  def change
    add_column :upvs_form_templates, :template, :text

    Upvs::FormTemplate.find_by(
      identifier: "App.GeneralAgenda",
      version: "1.9",
      message_type: "App.GeneralAgenda",
    )&.update(template: '<GeneralAgenda xmlns="http://schemas.gov.sk/form/App.GeneralAgenda/1.9">
  <subject>{{subject}}</subject>
  <text>{{text}}</text>
</GeneralAgenda>')
  end
end
