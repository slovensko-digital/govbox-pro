namespace :filters do
  desc "Retry the existing-navigation backfill without resetting preferences or subscriptions"
  task backfill_navigation: :environment do
    require Rails.root.join("db/migrate/20261022180300_backfill_personal_filter_navigation")
    BackfillPersonalFilterNavigation.new.up
  end

  desc "Report normalized saved-query collisions before personalized navigation cutover"
  task preflight: :environment do
    require Rails.root.join("db/migrate/20261022180100_finalize_filter_query_uniqueness")
    report = FinalizeFilterQueryUniqueness.new.collision_report
    puts JSON.pretty_generate(report)
    abort "Resolve saved-query collisions explicitly before cutover" if report.any?
  end
end
