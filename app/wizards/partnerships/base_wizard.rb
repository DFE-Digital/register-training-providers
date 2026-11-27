module Partnerships
  class BaseWizard
    include DfE::Wizard

    attr_reader :provider

    def initialize(provider:, **)
      @provider = provider
      super(**)
    end

    def check_your_answers?
      current_step_name == :check_your_answers
    end

    def partnership_form
      ::PartnershipForm.new(
        accredited_provider_id: accredited_provider_id,
        provider_id: training_provider_id,
        start_date_day: wizard_state[:start_date_day],
        start_date_month: wizard_state[:start_date_month],
        start_date_year: wizard_state[:start_date_year],
        end_date_day: wizard_state[:end_date_day],
        end_date_month: wizard_state[:end_date_month],
        end_date_year: wizard_state[:end_date_year],
        academic_year_ids: Array(wizard_state[:academic_year_ids])
      )
    end

    def previous_step_override
      return unless return_to_review?
      return unless %i[find_partner dates academic_years].include?(current_step_name)

      :check_your_answers if valid_path_to?(:check_your_answers)
    end

    def next_step_override
      return unless return_to_review?
      return unless current_step_name == :find_partner

      :check_your_answers if valid_path_to?(:check_your_answers)
    end

  private

    def build_steps_processor(root:, edges:)
      DfE::Wizard::StepsProcessor::Graph.draw(self, predicate_caller: state_store) do |graph|
        steps.each { |name, klass| graph.add_node(name, klass) }

        graph.root root
        edges.each { |from, to| graph.add_edge from:, to: }

        graph.before_next_step(:next_step_override)
        graph.before_previous_step(:previous_step_override)
      end
    end

    def build_route_strategy(path_helper, path_arguments)
      DfE::Wizard::RouteStrategy::ConfigurableRoutes.new(wizard: self, namespace: "partnerships") do |config|
        config.default_path_arguments = path_arguments

        steps.each_key do |step|
          config.map_step step, to: lambda { |_wizard, options, helpers|
            helpers.public_send(path_helper, step: step.to_s.tr("_", "-"), **path_arguments, **options)
          }
        end
      end
    end

    def wizard_state
      state_store.read.with_indifferent_access
    end

    def return_to_review?
      @current_step_params[:return_to_review].present?
    end
  end
end
