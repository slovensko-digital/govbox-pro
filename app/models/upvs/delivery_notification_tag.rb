class Upvs::DeliveryNotificationTag < ::Tag
  def self.find_or_create_for_tenant!(tenant)
    find_or_create_by!(
      type: self.to_s,
      tenant: tenant
    ) do |tag|
      tag.name = "Na prevzatie"
      tag.visible = true
    end
  end
end
