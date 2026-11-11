module Partnerships
  module Steps
    class TypesStep
      include DfE::Wizard::Step

      attribute :partnership_types, default: -> { [] }

      validate :at_least_one_type
      validate :types_must_be_available

      def self.permitted_params
        [{ partnership_types: [] }]
      end

      def self.model_name
        ActiveModel::Name.new(self, nil, "Partnerships::TypesStep")
      end

      def self.i18n_scope
        :activerecord
      end

      delegate :available_partnership_types, to: :wizard

      delegate :used_partnership_types, to: :wizard

      delegate :placement_available?, to: :wizard

    private

      def selected_types
        Array(partnership_types).compact_blank
      end

      def at_least_one_type
        return if selected_types.any?

        errors.add(:partnership_types, :blank)
      end

      def types_must_be_available
        return if selected_types.empty?
        return if (selected_types - available_partnership_types).empty?

        errors.add(:partnership_types, :inclusion)
      end
    end
  end
end
