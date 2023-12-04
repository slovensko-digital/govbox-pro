# == Schema Information
#
# Table name: tags
#
#  id            :bigint           not null, primary key
#  external_name :string
#  name          :string           not null
#  type          :string           not null
#  visible       :boolean          default(TRUE), not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  owner_id      :bigint
#  tenant_id     :bigint           not null
#
class SimpleTag < Tag
  def destroyable?
    true
  end
end
