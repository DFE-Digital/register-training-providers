module ProviderChanges
  module Steps
    class ReasonsStep
      include DfE::Wizard::Step
      include ActiveModel::Validations::Callbacks

      attribute :reasons, default: []
      attribute :other_reason, :string

      validate :at_least_one_reason
      validate :other_reason_present_if_selected
      validate :reasons_are_offered_reasons, unless: -> { errors.key?(:reasons) }

      validates :other_reason, length: { maximum: 255 }, allow_blank: true

      def self.permitted_params
        [{ reasons: [] }, :other_reason]
      end

      def reasons_for_inactive
        ProviderStatusEnum::REASONS_FOR_INACTIVE.map do |id, name|
          ReasonForInactive.new(id:, name:)
        end
      end

      def other_reason_selected?
        reasons.include?("other")
      end

      def other_reason_text
        other_reason
      end

    private

      class ReasonForInactive
        attr_reader :id, :name

        def initialize(id:, name:)
          @id = id
          @name = name
        end
      end

      def at_least_one_reason
        return true if reasons.compact_blank.present?

        errors.add(:reasons, :blank)
      end

      def other_reason_present_if_selected
        return true unless reasons.include?("other") && other_reason.blank?

        errors.add(:other_reason, :blank)
      end

      def reasons_are_offered_reasons
        return true if reasons.compact_blank.all? { |reason| ProviderStatusEnum::REASONS_FOR_INACTIVE.key?(reason) || reason == "other" }

        errors.add(:reasons, :inclusion)
      end
    end
  end
end
