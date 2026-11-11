module Providers
  module Partnerships
    class EndDateRemovalsController < ApplicationController
      def show
        authorize partnership

        return redirect_to(question_path) unless removing_end_date?

        setup_view_data
      end

      def create
        authorize partnership

        redirect_to wizard.next_step_path(return_to_review: params[:return_to_review])
      end

    private

      def partnership
        @partnership ||= provider.partnerships.kept.find(params[:partnership_id])
      end

      def provider
        @provider ||= Provider.kept.find(params[:provider_id])
      end

      def removing_end_date?
        partnership.duration.end.is_a?(Date) && state_has_no_end_date?
      end

      def state_has_no_end_date?
        wizard.state_store.read.with_indifferent_access[:has_end_date].to_s == "false"
      end

      def wizard
        @wizard ||= ::Partnerships::EditWizard.new(
          provider: provider,
          partnership: partnership,
          current_step: :end_date_question,
          current_step_params: params,
          state_store: state_store
        )
      end

      def state_store
        @state_store ||= ::Partnerships::StateStores::PartnershipStore.new(repository:)
      end

      def repository
        @repository ||= DfE::Wizard::Repository::Session.new(
          session: session,
          key: :"partnership_edit_#{partnership.id}"
        )
      end

      def question_path
        provider_partnership_edit_step_path(
          provider_id: provider.id,
          partnership_id: partnership.id,
          step: "end-date-question",
          return_to_review: params[:return_to_review]
        )
      end

      def setup_view_data
        @provider = provider
        @partnership = partnership
        @page_title = "Are you sure you want to remove the partnership end date?"
        @page_subtitle = provider.operating_name.to_s
        @page_caption = provider.operating_name.to_s
        @back_path = question_path
        @cancel_path = question_path
        @remove_path = provider_partnership_end_date_removal_path(
          partnership,
          provider_id: provider.id,
          return_to_review: params[:return_to_review]
        )
      end
    end
  end
end
