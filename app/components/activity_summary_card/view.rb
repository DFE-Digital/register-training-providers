module ActivitySummaryCard
  class View < ApplicationComponent
    include ProviderHelper
    include AccreditationHelper
    include AddressHelper
    include ContactHelper
    include PartnershipHelper
    include SummaryHelper

    attr_reader :audit, :show_title

    def initialize(audit:, show_title: true)
      @audit = audit
      @show_title = show_title
      super()
    end

    def record
      return @record if defined?(@record)

      @record = if audit.auditable_type == "Partnership"
                  audit.auditable
                else
                  audit.revision
                end
    end

    def title_text
      return nil unless show_title
      return nil unless record
      return nil if audit.auditable_type == "Partnership"

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
      return partnership_title if audit.auditable_type == "Partnership" && show_title && record
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
        accreditation_rows(record)
      when "Address"
        address_summary_card_rows(record)
      when "Contact"
        contact_rows(record)
      when "Partnership"
        partnership_rows(record)
      when "User"
        user_rows(record)
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

    def partnership_title
      accredited = record.accredited_provider
      training = record.provider

      accredited_link = provider_link_or_text(accredited)
      training_link = provider_link_or_text(training)

      helpers.safe_join([accredited_link, " – ", training_link])
    end

    def provider_link_or_text(prov)
      return prov.operating_name if prov.discarded?

      helpers.govuk_link_to(prov.operating_name, helpers.provider_partnerships_path(prov))
    end
  end
end
