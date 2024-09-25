# == Schema Information
#
# Table name: filters
#
#  id         :bigint           not null, primary key
#  icon       :string
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
class EverythingFilter < TagFilter
  before_validation :set_everything_tag
  after_create :move_to_top

  def self.model_name
    Filter.model_name
  end

  def query
    nil
  end

  private

  def set_everything_tag
    self.tag = tenant.everything_tag
  end
end
