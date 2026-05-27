class Fs::OnboardingService
  include ActiveModel::API
  attr_accessor :tenant_name, :ico, :admin_user_name, :saml_identifier, :admin_user_contact_email, :trial

  validates :tenant_name, :ico, :saml_identifier, :admin_user_name, :admin_user_contact_email, presence: true

  def initialize(params)
    @tenant_name = params[:tenant_name] if params[:tenant_name]
    @ico = params[:ico] if params[:ico]
    @saml_identifier = params[:saml_identifier] if params[:saml_identifier]
    @admin_user_name = params[:admin_user_name] if params[:admin_user_name]
    @admin_user_contact_email = params[:admin_user_contact_email] if params[:admin_user_contact_email]
    @fs_api_key = OpenSSL::PKey::RSA.new(2048)
    @trial = ActiveModel::Type::Boolean.new.cast(params[:trial])
  end

  def call(fs_client: FsEnvironment.fs_client)
    Tenant.transaction do
      tenant = Tenant.create!(name: @tenant_name, contact_email: @admin_user_contact_email, ico: @ico)
      tenant.update!(outbox_messages_limit: 50) if trial

      user = tenant.users.create!(name: @admin_user_name, saml_identifier: @saml_identifier).tap do |tenant_user|
        tenant_user.groups << tenant.admin_group
        tenant_user.groups << tenant.groups.find_by(type: "SignerGroup")

        tenant_user.save!
      end

      tenant.feature_flags = %w[fs_api fs_sync]
      tenant.save!

      response = fs_client.admin_api.create_user(
        crm_identifier: @tenant_name,
        api_token_public_key: @fs_api_key.public_key.to_pem
      )

      fs_api_sub = response["id"]

      Fs::ApiConnection.create!(tenant: tenant, sub: fs_api_sub, api_token_private_key: @fs_api_key.to_pem, owner: user, custom_name: "Prepojenie na portál finančnej správy")

      setup_automation_rules(tenant, user)

      tenant
    end
  end

  private

  def setup_automation_rules(tenant, user)
    overena_potvrdenka_tag = tenant.tags.create!(
      name: "S potvrdenkou",
      owner: user, type: "SimpleTag",
      color: "green",
      icon: "check"
    )

    neoverena_potvrdenka_tag = tenant.tags.create!(
      name: "S neoverenou potvrdenkou",
      owner: user,
      type: "SimpleTag",
      color: "orange",
      icon: "check"
    )

    tenant.filters.create!(
      author: user,
      name: "Bez potvrdenky",
      query: "-label:(S potvrdenkou) -label:(S neoverenou potvrdenkou) -label:(Rozpracované)"
    )

    # First rule - if ED.DeliveryReport is created with verified signatures
    overena_potvrdenka_rule = tenant.automation_rules.create!(
      name: "Pridaj štítok 'S potvrdenkou'",
      trigger_event: "message_created",
      user: user
    )
    overena_potvrdenka_rule.conditions.create!(
      attr: "fs_submission_status",
      type: "Automation::MetadataValueCondition",
      value: "Prijaté a potvrdené"
    )
    overena_potvrdenka_rule.conditions.create!(
      attr: "fs_message_type",
      type: "Automation::MetadataValueCondition",
      value: "ED.DeliveryReport"
    )
    overena_potvrdenka_rule.conditions.create!(
      attr: "fs_submission_verification_status.name",
      type: "Automation::MetadataValueCondition",
      value: "Platné"
    )
    overena_potvrdenka_rule.conditions.create!(
      attr: "fs_submission_verification_status.description",
      type: "Automation::MetadataValueCondition",
      value: "Overenie platnosti podpisov podania bolo ukončené. Všetky podpisy sú platné."
    )
    overena_potvrdenka_rule.actions.create!(
      type: "Automation::AddMessageThreadTagAction",
      action_object_type: "Tag",
      action_object_id: overena_potvrdenka_tag.id
    )

    # Second rule - if ED.DeliveryReport is created without verified signatures
    neoverena_potvrdenka_rule = tenant.automation_rules.create!(
      name: "Pridaj štítok 'S neoverenou potvrdenkou'",
      trigger_event: "message_created",
      user: user
    )
    neoverena_potvrdenka_rule.conditions.create!(
      attr: "fs_submission_status",
      type: "Automation::MetadataValueCondition",
      value: "Prijaté a potvrdené"
    )
    neoverena_potvrdenka_rule.conditions.create!(
      attr: "fs_message_type",
      type: "Automation::MetadataValueCondition",
      value: "ED.DeliveryReport"
    )
    neoverena_potvrdenka_rule.conditions.create!(
      attr: "fs_submission_verification_status.name",
      type: "Automation::MetadataValueNotCondition",
      value: "Platné"
    )
    neoverena_potvrdenka_rule.conditions.create!(
      attr: "fs_submission_verification_status.description",
      type: "Automation::MetadataValueNotCondition",
      value: "Overenie platnosti podpisov podania bolo ukončené. Všetky podpisy sú platné."
    )
    neoverena_potvrdenka_rule.actions.create!(
      type: "Automation::AddMessageThreadTagAction",
      action_object_type: "Tag",
      action_object_id: neoverena_potvrdenka_tag.id
    )

    # Third rule - when ED.DeliveryReport is updated - signatures are verified
    zmena_overenia_potvrdenky_rule = tenant.automation_rules.create!(
      name: "Pridaj štítok 'S neoverenou potvrdenkou' zmena",
      trigger_event: "message_updated",
      user: user
    )
    zmena_overenia_potvrdenky_rule.conditions.create!(
      attr: "fs_submission_status",
      type: "Automation::MetadataValueCondition",
      value: "Prijaté a potvrdené"
    )
    zmena_overenia_potvrdenky_rule.conditions.create!(
      attr: "fs_message_type",
      type: "Automation::MetadataValueCondition",
      value: "ED.DeliveryReport"
    )
    zmena_overenia_potvrdenky_rule.conditions.create!(
      attr: "fs_submission_verification_status.name",
      type: "Automation::MetadataValueCondition",
      value: "Platné"
    )
    zmena_overenia_potvrdenky_rule.conditions.create!(
      attr: "fs_submission_verification_status.description",
      type: "Automation::MetadataValueCondition",
      value: "Overenie platnosti podpisov podania bolo ukončené. Všetky podpisy sú platné."
    )
    zmena_overenia_potvrdenky_rule.actions.create!(
      type: "Automation::AddMessageThreadTagAction",
      action_object_type: "Tag",
      action_object_id: overena_potvrdenka_tag.id
    )
    zmena_overenia_potvrdenky_rule.actions.create!(
      type: "Automation::UnassignMessageThreadTagAction",
      action_object_type: "Tag",
      action_object_id: neoverena_potvrdenka_tag.id
    )

    # Fourth rule - Potvrdenka stiahnutá
    stiahnuta_potvrdenka_tag = tenant.tags.create!(
      name: "Potvrdenka stiahnutá",
      owner: user,
      type: "SimpleTag",
      color: 'yellow',
      icon: 'paper_clip'
    )

    tenant.filters.create!(
      author: user,
      name: "Potvrdenka nestiahnutá",
      query: "-label:(Potvrdenka stiahnutá) -label:(Rozpracované)"
    )

    stiahnuta_potvrdenka_rule = tenant.automation_rules.create!(
      name: "Pridaj štítok 'Potvrdenka stiahnutá'",
      trigger_event: "message_object_downloaded",
      user: user
    )
    stiahnuta_potvrdenka_rule.conditions.create!(
      attr: "object_type",
      type: "Automation::ContainsCondition",
      value: "FORM"
    )
    stiahnuta_potvrdenka_rule.conditions.create!(
      attr: "fs_message_type",
      type: "Automation::MessageMetadataValueCondition",
      value: "ED.DeliveryReport"
    )
    stiahnuta_potvrdenka_rule.actions.create!(
      type: "Automation::AddMessageThreadTagAction",
      action_object_type: "Tag",
      action_object_id: stiahnuta_potvrdenka_tag.id
    )
  end
end
