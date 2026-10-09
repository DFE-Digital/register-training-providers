module ProviderChanges
  module Steps
    class UrnStep
      include DfE::Wizard::Step
      include ActiveModel::Validations::Callbacks

      attribute :urn

      before_validation :normalise_blank_urn

      validates :urn,
                format: { with: /\A[0-9]{5,6}\z/ },
                if: -> { urn.present? }

      validate :urn_changed, if: -> { urn.present? && errors[:urn].empty? }

      def self.permitted_params
        %i[urn]
      end

    private

      def normalise_blank_urn
        self.urn = urn.to_s.strip.presence
      end

      def urn_changed
        errors.add(:urn, :same) if wizard.provider.urn == urn
      end
    end
  end
end
