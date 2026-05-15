class Fs::OnboardTenant
  include ActiveModel::API
  attr_accessor :tenant_name, :admin_user_name, :saml_identifier, :admin_user_contact_email, :fs_api_sub, :fs_api_private_key

  validates :tenant_name, :saml_identifier, :admin_user_name, :admin_user_contact_email, :fs_api_sub, :fs_api_private_key, presence: true

  def initialize(params)
    @tenant_name = params[:tenant_name] if params[:tenant_name]
    @saml_identifier = params[:saml_identifier] if params[:saml_identifier]
    @admin_user_name = params[:admin_user_name] if params[:admin_user_name]
    @admin_user_contact_email = params[:admin_user_contact_email] if params[:admin_user_contact_email]
    @fs_api_sub = params[:fs_api_sub] if params[:fs_api_sub]
    @fs_api_private_key = params[:fs_api_private_key] if params[:fs_api_private_key]
  end

  def call
    Tenant.transaction do
      tenant = Tenant.find_or_create_by!(name: @tenant_name)

      user = tenant.users.find_or_create_by!(contact_email: @admin_user_contact_email, name: @admin_user_name, saml_identifier: @saml_identifier).tap do |tenant_user|
        tenant_user.groups << tenant.admin_group
        tenant_user.groups << tenant.groups.find_by(type: "SignerGroup")
        tenant_user.save!
      end

      tenant.feature_flags = %w[fs_api fs_sync]
      tenant.save!

      Fs::ApiConnection.create!(tenant: tenant, sub: @fs_api_sub, api_token_private_key: @fs_api_private_key, owner: user)

      setup_automation_rules(tenant, user)

      tenant
    end
  end

  private

  def setup_automation_rules(tenant, user)
    overena_potvrdenka_tag = tenant.tags.find_or_create_by!(
      name: "S potvrdenkou",
      owner: user, type: "SimpleTag",
      color: "green",
      icon: "check"
    )

    neoverena_potvrdenka_tag = tenant.tags.find_or_create_by!(
      name: "S neoverenou potvrdenkou",
      owner: user,
      type: "SimpleTag",
      color: "orange",
      icon: "check"
    )

    tenant.filters.find_or_create_by!(
      author: user,
      name: "Bez potvrdenky",
      query: "-label:(S potvrdenkou) -label:(S neoverenou potvrdenkou) -label:(Rozpracované)"
    )

    # First rule - if ED.DeliveryReport is created with verified signatures
    overena_potvrdenka_rule = tenant.automation_rules.find_or_create_by!(
      name: "Pridaj štítok 'S potvrdenkou'",
      trigger_event: "message_created",
      user: user
    )
    overena_potvrdenka_rule.conditions.find_or_create_by!(
      attr: "fs_submission_status",
      type: "Automation::MetadataValueCondition",
      value: "Prijaté a potvrdené"
    )
    overena_potvrdenka_rule.conditions.find_or_create_by!(
      attr: "fs_message_type",
      type: "Automation::MetadataValueCondition",
      value: "ED.DeliveryReport"
    )
    overena_potvrdenka_rule.conditions.find_or_create_by!(
      attr: "fs_submission_verification_status.name",
      type: "Automation::MetadataValueCondition",
      value: "Platné"
    )
    overena_potvrdenka_rule.conditions.find_or_create_by!(
      attr: "fs_submission_verification_status.description",
      type: "Automation::MetadataValueCondition",
      value: "Overenie platnosti podpisov podania bolo ukončené. Všetky podpisy sú platné."
    )
    overena_potvrdenka_rule.actions.find_or_create_by!(
      type: "Automation::AddMessageThreadTagAction",
      action_object_type: "Tag",
      action_object_id: overena_potvrdenka_tag.id
    )

    # Second rule - if ED.DeliveryReport is created without verified signatures
    neoverena_potvrdenka_rule = tenant.automation_rules.find_or_create_by!(
      name: "Pridaj štítok 'S neoverenou potvrdenkou'",
      trigger_event: "message_created",
      user: user
    )
    neoverena_potvrdenka_rule.conditions.find_or_create_by!(
      attr: "fs_submission_status",
      type: "Automation::MetadataValueCondition",
      value: "Prijaté a potvrdené"
    )
    neoverena_potvrdenka_rule.conditions.find_or_create_by!(
      attr: "fs_message_type",
      type: "Automation::MetadataValueCondition",
      value: "ED.DeliveryReport"
    )
    neoverena_potvrdenka_rule.conditions.find_or_create_by!(
      attr: "fs_submission_verification_status.name",
      type: "Automation::MetadataValueNotCondition",
      value: "Platné"
    )
    neoverena_potvrdenka_rule.conditions.find_or_create_by!(
      attr: "fs_submission_verification_status.description",
      type: "Automation::MetadataValueNotCondition",
      value: "Overenie platnosti podpisov podania bolo ukončené. Všetky podpisy sú platné."
    )
    neoverena_potvrdenka_rule.actions.find_or_create_by!(
      type: "Automation::AddMessageThreadTagAction",
      action_object_type: "Tag",
      action_object_id: neoverena_potvrdenka_tag.id
    )

    # Third rule - when ED.DeliveryReport is updated - signatures are verified
    zmena_overenia_potvrdenky_rule = tenant.automation_rules.find_or_create_by!(
      name: "Pridaj štítok 'S neoverenou potvrdenkou' zmena",
      trigger_event: "message_updated",
      user: user
    )
    zmena_overenia_potvrdenky_rule.conditions.find_or_create_by!(
      attr: "fs_submission_status",
      type: "Automation::MetadataValueCondition",
      value: "Prijaté a potvrdené"
    )
    zmena_overenia_potvrdenky_rule.conditions.find_or_create_by!(
      attr: "fs_message_type",
      type: "Automation::MetadataValueCondition",
      value: "ED.DeliveryReport"
    )
    zmena_overenia_potvrdenky_rule.conditions.find_or_create_by!(
      attr: "fs_submission_verification_status.name",
      type: "Automation::MetadataValueCondition",
      value: "Platné"
    )
    zmena_overenia_potvrdenky_rule.conditions.find_or_create_by!(
      attr: "fs_submission_verification_status.description",
      type: "Automation::MetadataValueCondition",
      value: "Overenie platnosti podpisov podania bolo ukončené. Všetky podpisy sú platné."
    )
    zmena_overenia_potvrdenky_rule.actions.find_or_create_by!(
      type: "Automation::AddMessageThreadTagAction",
      action_object_type: "Tag",
      action_object_id: overena_potvrdenka_tag.id
    )
    zmena_overenia_potvrdenky_rule.actions.find_or_create_by!(
      type: "Automation::UnassignMessageThreadTagAction",
      action_object_type: "Tag",
      action_object_id: neoverena_potvrdenka_tag.id
    )

    tag2 = tenant.tags.find_or_create_by!(
      name: "Potvrdenka stiahnutá",
      owner: user,
      type: "SimpleTag",
      color: 'yellow',
      icon: 'paper_clip'
    )

    tenant.filters.find_or_create_by!(
      author: user,
      name: "Potvrdenka nestiahnutá",
      query: "-label:(Potvrdenka stiahnutá) -label:(Rozpracované)"
    )

    rule2 = tenant.automation_rules.find_or_create_by!(
      name: "Pridaj štítok 'Potvrdenka stiahnutá'",
      trigger_event: "message_object_downloaded",
      user: user
    )
    rule2.conditions.find_or_create_by!(
      attr: "object_type",
      type: "Automation::ContainsCondition",
      value: "FORM"
    )
    rule2.conditions.find_or_create_by!(
      attr: "fs_message_type",
      type: "Automation::MessageMetadataValueCondition",
      value: "ED.DeliveryReport"
    )
    rule2.actions.find_or_create_by!(
      type: "Automation::AddMessageThreadTagAction",
      action_object_type: "Tag",
      action_object_id: tag2.id
    )
  end
end
