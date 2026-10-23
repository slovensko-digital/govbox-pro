# frozen_string_literal: true

require_relative "20261022180100_finalize_filter_query_uniqueness"

class BackfillPersonalFilterNavigation < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  class LegacyTenant < ActiveRecord::Base
    self.table_name = "tenants"
  end

  class LegacyFilter < ActiveRecord::Base
    self.table_name = "filters"
  end

  class LegacyTag < ActiveRecord::Base
    self.table_name = "tags"
    self.inheritance_column = :_type_disabled
  end

  class LegacyUser < ActiveRecord::Base
    self.table_name = "users"
  end

  class Preference < ActiveRecord::Base
    self.table_name = "user_filter_visibilities"
  end

  SEED_KEY = "personal_filter_navigation_seed_ids"

  def up
    collisions = FinalizeFilterQueryUniqueness.new.collision_report
    raise "Duplicate saved queries require explicit resolution: #{collisions.inspect}" if collisions.any?

    LegacyTenant.find_each do |tenant|
      seed_ids = snapshot_shortcuts(tenant)
      # Revisit users on retries, including users created after an earlier pass.
      # Existing preferences (including explicit unpins) are never overwritten.
      LegacyUser.where(tenant_id: tenant.id).find_each(batch_size: 100) do |user|
        seed_preferences(user, seed_ids)
      end
      say "Tenant #{tenant.id}: retained filter/subscription IDs; seeded #{seed_ids.size} query shortcuts"
    end
    if index_exists?(:filters, [:tenant_id, :position], unique: true)
      remove_index :filters, [:tenant_id, :position]
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration, "Retain personal choices and existing subscriptions"
  end

  private

  def snapshot_shortcuts(tenant)
    tenant.with_lock do
      existing_seed = tenant.settings[SEED_KEY]
      next existing_seed if existing_seed

      original_ids = LegacyFilter.where(tenant_id: tenant.id, common: true).order(:position, :id).pluck(:id)
      all = ensure_common_filter(tenant.id, "", "Všetky správy")
      tag_filter_ids = LegacyTag.where(tenant_id: tenant.id, visible: true).order(:name, :id).map do |tag|
        ensure_common_filter(tenant.id, "label:(#{tag.name})", tag.name).id
      end
      ids = ([all.id] + original_ids + tag_filter_ids).uniq
      tenant.update!(settings: tenant.settings.merge(SEED_KEY => ids))
      ids
    end
  end

  def ensure_common_filter(tenant_id, query, name)
    LegacyFilter.find_by(tenant_id: tenant_id, common: true, query: query) ||
      LegacyFilter.create!(tenant_id: tenant_id, common: true, query: query, name: name,
        position: (LegacyFilter.where(tenant_id: tenant_id).maximum(:position) || 0) + 1)
  end

  def seed_preferences(user, seed_ids)
    user.with_lock do
      existing = Preference.where(user_id: user.id).index_by(&:filter_id)
      position = existing.values.map(&:position).max || 0
      available = LegacyFilter.where(tenant_id: user.tenant_id, common: true, id: seed_ids).index_by(&:id)
      personal_queries = LegacyFilter.where(tenant_id: user.tenant_id, common: false, author_id: user.id).pluck(:query)
      seed_ids.each do |filter_id|
        next if existing.key?(filter_id) || !available.key?(filter_id)

        position += 1
        Preference.create!(user_id: user.id, filter_id: filter_id, position: position,
          visible: !personal_queries.include?(available.fetch(filter_id).query))
      end
    end
  end
end
