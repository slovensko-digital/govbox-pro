# == Schema Information
#
# Table name: filters
#
#  id         :bigint           not null, primary key
#  is_pinned  :boolean          default(FALSE), not null
#  name       :string           not null
#  position   :integer          not null
#  query      :string
#  type       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  author_id  :bigint
#  tag_id     :bigint
#  tenant_id  :bigint           not null
#
class FulltextFilter < Filter
  validates :query, presence: true

  def self.model_name
    Filter.model_name
  end
end
