module ProviderChanges
  module Steps
    class CodeStep
      include DfE::Wizard::Step
      include ActiveModel::Validations::Callbacks

      attribute :code

      before_validation :upcase_code

      validates :code,
                presence: true,
                format: { with: /\A[A-Z0-9]{3}\z/i },
                length: { is: 3 }

      validate :code_is_available, unless: -> { errors.key?(:code) }

      def self.permitted_params
        %i[code]
      end

    private

      def upcase_code
        self.code = code&.upcase
      end

      def code_is_available
        errors.add(:code, :taken) if ProviderCodeTakenService.call(
          code: code, effective_on: wizard.state_store.effective_on
        )
      end
    end
  end
end
