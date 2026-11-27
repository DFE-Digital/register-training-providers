module Providers
  module Partnerships
    class TypeChangesController < ApplicationController
      def show
        authorize partnership

        return redirect_to(types_path) if selected_types.empty? || !types_changed?

        setup_view_data
      end

      def create
        authorize partnership

        redirect_to wizard.next_step_path(return_to_review: params[:return_to_review])
      end

    private

      def partnership
        @partnership ||= provider.partnerships.kept.find(params.expect(:partnership_id))
      end

      def provider
        @provider ||= Provider.kept.find(params.expect(:provider_id))
      end

      def selected_types
        wizard.selected_partnership_types.map(&:to_s)
      end

      def kept_types
        partnership.partnership_types.kept.map(&:partnership_type)
      end

      def removed_types
        kept_types - selected_types
      end

      def added_types
        selected_types - kept_types
      end

      def types_changed?
        removed_types.any? || added_types.any?
      end

      def wizard
        @wizard ||= ::Partnerships::EditWizard.new(
          provider: provider,
          partnership: partnership,
          current_step: :types,
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

      def types_path
        provider_partnership_edit_step_path(
          provider_id: provider.id,
          partnership_id: partnership.id,
          step: "types",
          return_to_review: params[:return_to_review]
        )
      end

      def setup_view_data
        @provider = provider
        @partnership = partnership
        @page_title = page_title
        @page_subtitle = provider.operating_name.to_s
        @page_caption = provider.operating_name.to_s
        @ending_message = ending_message
        @confirm_label = confirm_label
        @back_path = types_path
        @cancel_path = types_path
        @confirm_path = provider_partnership_type_change_path(
          partnership,
          provider_id: provider.id,
          return_to_review: params[:return_to_review]
        )
      end

      def page_title
        if removed_types.any? && added_types.empty?
          type_question("remove", removed_types)
        elsif added_types.any? && removed_types.empty?
          type_question("add", added_types)
        else
          "Are you sure you want to change the partnership types?"
        end
      end

      def type_question(verb, types)
        labels = types.map { |type| PartnershipTypeEnum.label_for(type).downcase }

        if labels.one?
          "Are you sure you want to #{verb} the #{labels.first} type?"
        else
          "Are you sure you want to #{verb} the #{labels.to_sentence} types?"
        end
      end

      def ending_message
        date = Time.zone.today.to_fs(:govuk)

        if removed_types.any? && added_types.empty?
          "Ending #{types_phrase(removed_types)} will be today, #{date}. " \
            "The partnership will then appear in historic partnerships."
        elsif added_types.any? && removed_types.empty?
          "Adding #{types_phrase(added_types)} will end the current partnership today, #{date}. " \
            "The partnership will then appear in historic partnerships."
        else
          "Changing these partnership types will end the current partnership today, #{date}. " \
            "The partnership will then appear in historic partnerships."
        end
      end

      def types_phrase(types)
        types.one? ? "this partnership type" : "these partnership types"
      end

      def confirm_label
        return "Add" if added_types.any? && removed_types.empty?
        return "Change" if removed_types.any? && added_types.any?

        "Remove"
      end
    end
  end
end
