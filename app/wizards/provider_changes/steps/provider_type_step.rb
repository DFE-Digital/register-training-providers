module ProviderChanges
  module Steps
    class ProviderTypeStep
      include DfE::Wizard::Step

      attribute :provider_type, :string

      validates :provider_type, presence: true,
                                inclusion: { in: ProviderTypeEnum::PROVIDER_TYPES.values,
                                             allow_blank: true }

      validate :provider_type_changed, unless: -> { errors.key?(:provider_type) }

      def self.permitted_params
        %i[provider_type]
      end

    private

      def provider_type_changed
        errors.add(:provider_type, :same) if wizard.provider.provider_type == provider_type
      end
    end
  end
end
