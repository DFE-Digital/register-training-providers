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
      state = wizard_state
      has_end_date = state[:has_end_date].to_s != "false"

      ::PartnershipForm.new(
        accredited_provider_id: accredited_provider_id,
        provider_id: training_provider_id,
        start_date_day: state[:start_date_day],
        start_date_month: state[:start_date_month],
        start_date_year: state[:start_date_year],
        end_date_day: has_end_date ? state[:end_date_day] : nil,
        end_date_month: has_end_date ? state[:end_date_month] : nil,
        end_date_year: has_end_date ? state[:end_date_year] : nil,
        academic_year_ids: Array(state[:academic_year_ids]),
        eligible_academic_year_ids: eligible_academic_year_ids
      )
    end

    def eligible_academic_year_ids
      eligible_academic_years.pluck(:id).map(&:to_s)
    end

    def eligible_academic_years
      state = wizard_state
      start_date = state[:start_date]
      return AcademicYear.none if start_date.blank?

      end_date = if state[:has_end_date].to_s == "false"
                   default_end_date
                 else
                   state[:end_date] || default_end_date
                 end

      return AcademicYear.none if end_date <= start_date

      AcademicYear.where("duration && daterange(?, ?)", start_date, end_date).order(duration: :desc)
    end

    def previous_step_override
      return unless return_to_review?
      return unless %i[find_partner
                       types
                       start_date
                       end_date_question
                       end_date
                       academic_years].include?(current_step_name)

      :check_your_answers if valid_path_to?(:check_your_answers)
    end

    def next_step_override
      return unless return_to_review?
      return unless %i[find_partner types].include?(current_step_name)

      :check_your_answers if valid_path_to?(:check_your_answers)
    end

  private

    def build_steps_processor(root:, edges:, conditional_edges: [])
      DfE::Wizard::StepsProcessor::Graph.draw(self, predicate_caller: state_store) do |graph|
        steps.each { |name, klass| graph.add_node(name, klass) }

        graph.root root
        edges.each { |from, to| graph.add_edge from:, to: }
        conditional_edges.each { |edge| graph.add_conditional_edge(**edge) }

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

    def default_end_date
      next_year = Time.zone.today + 1.year
      fallback = Time.zone.today + 2.years

      AcademicYear.find_by("duration @> ?::date", next_year)&.duration&.end || fallback
    end
  end
end
