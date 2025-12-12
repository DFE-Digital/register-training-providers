module ActivitySummaryCard
  class View < ApplicationComponent
    include ProviderHelper
    include AccreditationHelper
    include AddressHelper
    include ContactHelper
    include SummaryHelper

    attr_reader :audit, :show_title

    def initialize(audit:, show_title: true)
      @audit = audit
      @show_title = show_title
      super()
    end

    def record
      @record ||= audit.revision
    end

    def title
      return nil unless show_title
      return nil unless record

      case audit.auditable_type
      when "Provider"
        record.operating_name
      when "Accreditation", "Address", "Contact"
        audit.associated&.operating_name
      when "User"
        record.name
      end
    end

    def rows
      return [] unless record

      case audit.auditable_type
      when "Provider"
        provider_summary_card_rows(record)
      when "Accreditation"
        accreditation_rows(record) # reuse existing helper
      when "Address"
        address_summary_card_rows(record)
      when "Contact"
        contact_rows(record) # reuse existing helper
      when "User"
        user_rows(record) # reuse existing helper
      else
        []
      end
    end

    def render?
      record.present? && rows.any?
    end
  end
end
