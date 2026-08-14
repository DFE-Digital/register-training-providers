class BackfillRotpIdToProviders < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def up
    say_with_time "Backfilling rotp_id for #{providers.count} providers" do
      providers = Provider.where(rotp_id: nil)

      providers.find_each do |provider|
        SaveProviderWithRotpIdService.call(provider, validate: false)
      end
    end
  end

  def down
    # NOTE: We don't want to remove rotp_id values on rollback
  end
end
