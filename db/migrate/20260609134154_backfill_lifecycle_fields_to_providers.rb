class BackfillLifecycleFieldsToProviders < ActiveRecord::Migration[8.1]
  def up
    say_with_time "Backfilling provider lifecycle fields" do
      Provider.includes(:academic_years)
        .where(onboarded_at: nil)
        .find_each do |provider|
        lifecycle = ProviderLifecycleCalculator.call(provider.academic_years)

        provider.update_columns(lifecycle)
      end
    end
  end

  def down
    # NOTE: there is no need to reverse this migration as the fields being backfilled.
  end
end
