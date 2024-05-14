module MessageHelper
  def self.export_name(message)
    "#{message.delivered_at.to_date}-sprava-#{message.id}.zip"
  end
end
