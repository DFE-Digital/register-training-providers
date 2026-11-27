module ProviderChanges
  class StatusWizard < BaseWizard
    def steps_processor
      DfE::Wizard::StepsProcessor::Graph.draw(self, predicate_caller: state_store) do |graph|
        steps.each { |name, klass| graph.add_node(name, klass) }

        graph.root :new_status

        graph.add_conditional_edge(
          from: :new_status,
          when: -> { reason_capture_required? },
          label: "reason_capture_required?",
          then: :reasons,
          else: :effective_date
        )
        graph.add_edge from: :reasons, to: :effective_date
        graph.add_edge from: :effective_date, to: :check_your_answers

        graph.before_next_step(:next_step_override)
        graph.before_previous_step(:previous_step_override)
      end
    end

    def provider_change_attributes
      state = state_store.read.with_indifferent_access

      {
        attribute_name: "status",
        effective_on: state["effective_on"],
        value: status_change_value
      }
    end

    def set_state_store(provider_change)
      return if provider_change.blank?

      value = provider_change.value || {}

      state_store.write(
        new_status: value["status"],
        reasons: value["reason_ids"] || [],
        other_reason: value["other_reason"],
        effective_on: provider_change.effective_on
      )
    end

  private

    def reason_capture_required?
      new_status = state_store.read.with_indifferent_access["new_status"]

      [ProviderStatusEnum::INACTIVE, ProviderStatusEnum::OFFBOARDED].include?(new_status)
    end

    def field
      "status"
    end

    def steps
      {
        new_status: ProviderChanges::Steps::StatusStep,
        reasons: ProviderChanges::Steps::ReasonsStep,
        effective_date: ProviderChanges::Steps::StatusEffectiveDateStep,
        check_your_answers: ProviderChanges::Steps::CheckYourAnswersStep
      }
    end

    def status_change_value
      state = state_store.read.with_indifferent_access
      value = { "status" => state["new_status"] }
      reason_ids = state["new_status"] == ProviderStatusEnum::ACTIVE ? [] : Array(captured_reason_ids).compact_blank

      if reason_ids.present?
        value["reason_ids"] = reason_ids

        if reason_ids.include?("other") && state["other_reason"].present?
          value["other_reason"] = state["other_reason"]
        end
      end

      value
    end

    def captured_reason_ids
      Array(step(:reasons)&.reasons)
    end
  end
end
