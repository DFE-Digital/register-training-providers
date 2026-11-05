class BackfillOpenInactivePeriodsForArchivedProviders < ActiveRecord::Migration[8.1]
  def up
    providers = Provider.where.not(archived_at: nil)
      .where("inactive_periods @> ?", [{ end_date: nil }].to_json)

    say_with_time "Closing open inactive periods for #{providers.count} archived providers" do
      providers.find_each do |provider|
        provider.close_open_inactive_periods(ending_on: provider.archived_at.to_date)
        provider.update_columns(inactive_periods: provider.inactive_periods)
      end
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
