module Upvs
  def self.table_name_prefix
    "upvs_"
  end

  def self.env
    @env ||= ActiveSupport::StringInquirer.new(ENV.fetch('UPVS_ENV', 'fix'))
  end
end
