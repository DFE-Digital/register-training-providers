module ProviderChanges
  class UkprnWizard
    include DfE::Wizard

    attr_reader :provider

    def initialize(provider:, **)
      @provider = provider
      super(**)
    end

    def steps_processor
      DfE::Wizard::StepsProcessor::Graph.draw(self, predicate_caller: state_store) do |graph|
        graph.add_node :effective_date, ProviderChanges::Steps::EffectiveDateStep
        graph.add_node :new_ukprn, ProviderChanges::Steps::UkprnStep
        graph.add_node :check_your_answers, ProviderChanges::Steps::CheckYourAnswersStep

        graph.root :effective_date

        graph.add_edge from: :effective_date, to: :new_ukprn
        graph.add_edge from: :new_ukprn, to: :check_your_answers

        graph.before_next_step(:next_step_override)
        graph.before_previous_step(:previous_step_override)
      end
    end

    def next_step_override
      target = @current_step_params[:return_to_review]&.to_sym

      :check_your_answers if target.present? && valid_path_to?(:check_your_answers)
    end

    def previous_step_override
      target = @current_step_params[:return_to_review]&.to_sym

      :check_your_answers if current_step_name == target && valid_path_to?(:check_your_answers)
    end

    def route_strategy
      DfE::Wizard::RouteStrategy::ConfigurableRoutes.new(
        wizard: self,
        namespace: "provider_changes"
      ) do |config|
        config.default_path_arguments = {
          provider_id: provider.id,
          field: "ukprn"
        }
        %i[
          effective_date
          new_ukprn
          check_your_answers
        ].each do |step|
          config.map_step step, to: ->(_wizard, options, helpers) {
            helpers.provider_change_update_step_path(
              step: step.to_s.tr("_", "-"),
              **options
            )
          }
        end
      end
    end

    def check_your_answers?
      current_step_name == :check_your_answers
    end

    def logger
      DfE::Wizard::Logging::Logger.new(Rails.logger) if Rails.env.development?
    end

    def first_step?
      current_step_name == :effective_date
    end

    def set_state_store(provider_change)
      return if provider_change.blank?

      attributes = {
        provider_change.attribute_name.to_sym => provider_change.value,
        :effective_on => provider_change.effective_on
      }
      state_store.write(attributes)
    end

    def provider_change_attributes
      state = state_store.read.with_indifferent_access

      {
        attribute_name: "ukprn",
        effective_on: state["effective_on"],
        value: state["ukprn"]
      }
    end
  end
end
