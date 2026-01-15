module Providers
  module Partnerships
    class FindController < ApplicationController
      include PartnershipJourneyController

      PartnerOption = Struct.new(:name, :value, :hint, :search_text, keyword_init: true)

      def new
        # Clear session for fresh start, keep data only when editing from confirm page
        if params[:goto] == "confirm"
          partnership_data = partnership_session.load_partnership
        else
          partnership_session.clear!
          partnership_data = nil
        end

        @form = ::Partnerships::FindForm.new(
          partner_id: partnership_data&.dig(:partner_id),
          provider_accredited: provider.accredited?
        )
        @partners = load_eligible_partners

        setup_view_data
      end

      def create
        @form = ::Partnerships::FindForm.new(
          partner_id: params.dig(:find, :partner_id),
          provider_accredited: provider.accredited?
        )

        if @form.valid?
          partnership_session.store_partnership(
            partner_id: params.dig(:find, :partner_id),
            training_partner_search: provider.accredited?,
          )

          redirect_to dates_path
        else
          @partners = load_eligible_partners
          setup_view_data
          render :new
        end
      end

    private

      def load_eligible_partners
        providers = if provider.accredited?
                      Provider.where(provider_type: ProviderTypeEnum::UNACCREDITED_PROVIDER_TYPES.keys)
                        .order(:operating_name)
                    else
                      Provider.accredited.order(:operating_name)
                    end

        providers.map do |p|
          PartnerOption.new(
            name: p.operating_name,
            value: p.id,
            hint: partner_hint(p),
            search_text: partner_search_text(p)
          )
        end
      end

      def partner_hint(provider_record)
        parts = ["Provider code: #{provider_record.code}", "UKPRN: #{provider_record.ukprn}"]
        parts << "URN: #{provider_record.urn}" if provider_record.urn.present?
        parts.join(", ")
      end

      def partner_search_text(provider_record)
        parts = [provider_record.operating_name, provider_record.code, provider_record.ukprn]
        parts << provider_record.urn if provider_record.urn.present?
        parts.join(" | ")
      end

      def dates_path
        return provider_new_partnership_confirm_path(provider) if params[:goto] == "confirm"

        provider_new_partnership_dates_path(provider)
      end

      def back_path
        return provider_new_partnership_confirm_path(provider) if params[:goto] == "confirm"

        provider_partnerships_path(provider)
      end

      def form_url
        provider_partnership_find_path(provider)
      end

      def cancel_path
        provider_partnerships_path(provider)
      end

      def page_subtitle
        provider.operating_name.to_s
      end

      def page_caption
        "Add partnership - #{@provider.operating_name}"
      end

      def setup_view_data
        @back_path = back_path
        @form_url = form_url
        @cancel_path = cancel_path
        @page_title = page_title
        @page_subtitle = page_subtitle
        @page_caption = page_caption
        @provider_accredited = provider.accredited?
      end

      def page_title
        if provider.accredited?
          "Enter training partner name, code, UKPRN or URN"
        else
          "Enter accredited provider name, code, UKPRN or URN"
        end
      end
    end
  end
end
