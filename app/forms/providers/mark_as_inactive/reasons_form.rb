module Providers
  module MarkAsInactive
    class ReasonsForm
      include ActiveModel::Model
      include ActiveModel::Attributes
      include ActiveModel::Validations::Callbacks

      REASONS_FOR_INACTIVE = {
        "no_current_cohorts" => "No current cohorts",
        "operations_temporarily_paused" => "Operations temporarily paused",
        "staffing_of_capacity_issues" => "Staffing or capacity issues",
        "financial_viability" => "Financial viability"
      }.freeze

      attribute :reasons
      attribute :other_reason, :string

      validate :at_least_one_reason

      validate :other_reason_present_if_selected

      def self.i18n_scope
        :activerecord
      end

      def reasons_for_inactive
        reason_for_inactive = Struct.new(:id, :name)

        REASONS_FOR_INACTIVE.map { |k, v| reason_for_inactive.new(id: k, name: v) }
      end

      def transformed_reasons
        all_reasons = reasons.map { |reason| REASONS_FOR_INACTIVE[reason] }
        all_reasons << other_reason if reasons.include?("other")

        all_reasons.compact
      end

      def other_reason_selected?
        other_reason_text.present?
      end

      def other_reason_text
        (reasons - REASONS_FOR_INACTIVE.map { |_k, v| v }).first
      end

    private

      def at_least_one_reason
        return true if reasons.reject!(&:empty?).present?

        errors.add(:reasons, :blank)
      end

      def other_reason_present_if_selected
        return true unless reasons.include?("other") && other_reason.blank?

        errors.add(:other_reason, :blank)
      end
    end
  end
end
