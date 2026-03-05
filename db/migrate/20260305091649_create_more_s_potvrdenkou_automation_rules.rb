class UpdateSPotvrdenkouAutomationRule2 < ActiveRecord::Migration[7.1]
  def up
    Automation::Condition.where(attr: "fs_submission_status", type: "Automation::MetadataValueCondition", value: "Prijaté a potvrdené").find_each do |condition|
      # Existing rule - if ED.DeliveryReport is created with verified signatures
      overena_potvrdenka_rule = condition.automation_rule
      tenant = overena_potvrdenka_rule.tenant
      user = overena_potvrdenka_rule.user

      neoverena_potvrdenka_tag = tenant.tags.find_or_create_by(
        name: "S neoverenou potvrdenkou",
        owner: user,
        type: "SimpleTag",
        color: "orange",
        icon: "check"
      )
      overena_potvrdenka_tag = tenant.tags.find_by(
        name: "S potvrdenkou",
        type: "SimpleTag"
      )

      filter = tenant.filters.find_by(
        name: "Bez potvrdenky",
        query: "-label:(S potvrdenkou) -label:(Rozpracované)"
      )
      filter.update(
        query: "-label:(S potvrdenkou) -label:(S neoverenou potvrdenkou) -label:(Rozpracované)"
      ) if filter

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
        name: "Pridaj štítok 'S neoverenou potvrdenkou'",
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
    end
  end
end
