module ProviderChanges
  module Steps
    class UrnStep
      include DfE::Wizard::Step
      include ActiveModel::Validations::Callbacks

      attribute :urn

      validates :urn, presence: true, if: :urn_required?

      validates :urn,
                format: { with: /\A[0-9]{5,6}\z/ },
                length: { in: 5..6 },
                if: -> { urn.present? }

      validate :urn_changed, if: -> { urn.present? && errors[:urn].empty? }

      def self.permitted_params
        %i[urn]
      end

      def urn_required?
        wizard.provider.requires_urn?
      end

    private

      def urn_changed
        errors.add(:urn, :same) if wizard.provider.urn == urn
      end
    end
  end
end
