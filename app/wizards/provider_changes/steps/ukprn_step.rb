module ProviderChanges
  module Steps
    class UkprnStep
      include DfE::Wizard::Step
      include ActiveModel::Validations::Callbacks

      attribute :ukprn

      validates :ukprn,
                presence: true,
                format: { with: /\A[0-9]{8}\z/ },
                length: { is: 8 }

      validate :ukprn_changed, unless: -> { errors.key?(:ukprn) }

      def self.permitted_params
        %i[ukprn]
      end

    private

      def ukprn_changed
        errors.add(:ukprn, :same) if wizard.provider.ukprn == ukprn
      end
    end
  end
end
