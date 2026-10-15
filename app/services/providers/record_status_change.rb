module Providers
  class RecordStatusChange
    include ServicePattern

    def initialize(provider:, status_value:, creator: nil, previous_status: nil, effective_on: Date.current)
      @provider = provider
      @status_value = status_value
      @creator = creator
      @previous_status = previous_status
      @effective_on = effective_on
    end

    def call
      ActiveRecord::Base.transaction do
        record_baseline if baseline_missing?

        provider.provider_changes.create!(
          attribute_name: "status",
          value: change_value,
          effective_on: effective_on,
          status: :completed,
          source: creator ? :requested : :system,
          creator: creator
        )
      end
    end

  private

    attr_reader :provider, :status_value, :creator, :previous_status, :effective_on

    def change_value
      value = { "status" => status_value }
      value["previous_status"] = previous_status if previous_status.present?

      value
    end

    def record_baseline
      ProviderChangeBaselineService.call(
        provider: provider,
        attribute_name: "status",
        status_before_change: previous_status
      )
    end

    def baseline_missing?
      provider.provider_changes.completed.for_attribute("status").none?
    end
  end
end
