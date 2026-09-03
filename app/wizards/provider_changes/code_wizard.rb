module ProviderChanges
  class CodeWizard
    include DfE::Wizard

    attr_reader :provider

    def initialize(provider:, **)
      @provider = provider
      super(**)
    end

    def steps_processor
      DfE::Wizard::StepsProcessor::Graph.draw(self, predicate_caller: state_store) do |graph|
        graph.add_node :effective_academic_year, ProviderChanges::Steps::EffectiveAcademicYearStep
        graph.add_node :provider_code, ProviderChanges::Steps::CodeStep
        graph.add_node :check_your_answers, ProviderChanges::Steps::CheckYourAnswersStep

        graph.root :effective_academic_year

        graph.add_edge from: :effective_academic_year, to: :provider_code
        graph.add_edge from: :provider_code, to: :check_your_answers

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
          field: "code"
        }

        config.map_step :effective_academic_year, to: ->(_wizard, options, helpers) {
          helpers.provider_change_update_changes_path(**options)
        }

        config.map_step :provider_code, to: ->(_wizard, options, helpers) {
          helpers.provider_change_update_step_path(
            step: :provider_code,
            **options
          )
        }

        config.map_step :check_your_answers, to: ->(_wizard, options, helpers) {
          helpers.provider_change_update_step_path(
            step: :check_your_answers,
            **options
          )
        }
      end
    end

    def logger
      DfE::Wizard::Logging::Logger.new(Rails.logger) if Rails.env.development?
    end
  end
end
