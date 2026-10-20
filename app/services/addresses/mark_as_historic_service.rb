module Addresses
  class MarkAsHistoricService
    include ServicePattern

    def initialize(provider_id:, new_address_id:, type:)
      @provider_id = provider_id
      @type = type
      @new_address_id = new_address_id
    end

    def call
      address = old_address

      return unless address

      address.effective_end_dates[@type] = Time.zone.today

      address.save!
    end

  private

    def old_address
      provider = Provider.find(@provider_id)

      provider.addresses.kept.where.not(id: @new_address_id).where("types @> ARRAY[?]::varchar[]", [@type]).where.not(
        "effective_end_dates ? :key", key: @type
      ).first
    end
  end
end
