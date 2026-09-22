module ProviderChanges
  class BaseWizard
    include DfE::Wizard

    attr_reader :provider

    def initialize(provider:, **)
      @provider = provider
      super(**)
    end

    def steps_processor
      DfE::Wizard::StepsProcessor::Graph.draw(self, predicate_caller: state_store) do |graph|
        steps.each { |name, klass| graph.add_node(name, klass) }

        graph.root root_step

        step_sequence.each_cons(2) do |from, to|
          graph.add_edge from:, to:
        end

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
          field: field
        }
        step_sequence.each do |step|
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

    def set_state_store(provider_change)
      return if provider_change.blank?

      attributes = {
        provider_change.attribute_name.to_sym => provider_change.value,
        :effective_on => provider_change.effective_on
      }
      state_store.write(attributes)
    end

    def first_step?
      current_step_name == root_step
    end

  private

    # Subclasses declare their field and the ordered steps that make up the flow.
    def field
      raise NotImplementedError
    end

    def steps
      raise NotImplementedError
    end

    def root_step
      step_sequence.first
    end

    def step_sequence
      steps.keys
    end
  end
end
