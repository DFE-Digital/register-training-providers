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

    def title_text
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

    def title_link_path
      return nil unless linkable?

      case audit.auditable_type
      when "Provider"
        helpers.provider_path(provider)
      when "Contact"
        helpers.provider_contacts_path(provider)
      when "Address"
        helpers.provider_addresses_path(provider)
      when "Accreditation"
        helpers.provider_accreditations_path(provider)
      when "User"
        helpers.user_path(audit.auditable)
      end
    end

    def title
      return nil unless title_text

      if title_link_path
        helpers.govuk_link_to(title_text, title_link_path)
      else
        title_text
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

  private

    def provider
      @provider ||= case audit.auditable_type
                    when "Provider"
                      audit.auditable
                    when "Accreditation", "Address", "Contact"
                      audit.associated
                    end
    end

    def linkable?
      if provider.present?
        !provider.discarded?
      elsif audit.auditable_type == "User"
        audit.auditable.present? && !audit.auditable.discarded?
      else
        false
      end
    end
  end
end
