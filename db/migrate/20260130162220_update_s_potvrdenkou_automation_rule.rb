class UpdateSPotvrdenkouAutomationRule < ActiveRecord::Migration[7.1]
  def up
    Automation::Condition.where(attr: "fs_submission_status", type: "Automation::MetadataValueCondition", value: "Prijaté a potvrdené").find_each do |condition|
      condition.automation_rule.conditions.find_or_create_by!(
        attr: "fs_submission_verification_status",
        type: "Automation::MetadataValueCondition",
        value: {"name"=>"Platné", "description"=>"Overenie platnosti podpisov podania bolo ukončené. Všetky podpisy sú platné."}.to_s
      )
    end
  end
end
