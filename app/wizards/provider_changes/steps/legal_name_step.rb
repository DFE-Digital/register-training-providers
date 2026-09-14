module ProviderChanges
  module Steps
    class LegalNameStep
      include DfE::Wizard::Step
      include ActiveModel::Validations::Callbacks

      attribute :legal_name

      before_validation :strip_legal_name

      validate :legal_name_changed, if: -> { legal_name.present? }

      def self.permitted_params
        %i[legal_name]
      end

    private

      def strip_legal_name
        self.legal_name = legal_name&.strip
      end

      def legal_name_changed
        errors.add(:legal_name, :same) if wizard.provider.legal_name.to_s.strip == legal_name
      end
    end
  end
end
