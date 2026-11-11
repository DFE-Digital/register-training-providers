module Partnerships
  module Steps
    class EndDateQuestionStep
      include DfE::Wizard::Step

      attribute :has_end_date, :string

      validates :has_end_date, inclusion: { in: %w[true false] }

      def self.permitted_params
        %i[has_end_date]
      end

      def self.model_name
        ActiveModel::Name.new(self, nil, "Partnerships::EndDateQuestionStep")
      end

      def self.i18n_scope
        :activerecord
      end
    end
  end
end
