class UpdateSPotvrdenkouAutomationRule < ActiveRecord::Migration[7.1]
  def up
    Automation::Condition.where(attr: "fs_submission_status", type: "Automation::MetadataValueCondition", value: "Prijaté a potvrdené").find_each do |condition|
      condition.automation_rule.conditions.find_or_create_by!(
        attr: "fs_submission_verification_status.name",
        type: "Automation::MetadataValueCondition",
        value: "Platné"
      )

      condition.automation_rule.conditions.find_or_create_by!(
        attr: "fs_submission_verification_status.description",
        type: "Automation::MetadataValueCondition",
        value: "Overenie platnosti podpisov podania bolo ukončené. Všetky podpisy sú platné."
      )
    end
  end
end
